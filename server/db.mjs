import mysql from 'mysql2/promise'

let pool

function getPool() {
  if (!process.env.DATABASE_URL) throw new Error('Project DATABASE_URL is required')
  if (!pool) {
    pool = mysql.createPool({
      uri: process.env.DATABASE_URL,
      connectionLimit: 4,
      waitForConnections: true,
      connectTimeout: 5000,
      timezone: 'Z',
      dateStrings: true,
    })
  }
  return pool
}

function profileFromRow(row, runs) {
  return {
    displayName: row?.display_name ?? '',
    highestStage: Number(row?.highest_stage ?? 0),
    totalCoins: Number(row?.total_coins ?? 0),
    reputation: Number(row?.reputation ?? 52),
    bestScore: Number(row?.best_score ?? 0),
    bestDurationMs: row?.best_duration_ms == null ? null : Number(row.best_duration_ms),
    tutorialVersion: Number(row?.tutorial_version ?? 0),
    updatedAt: row?.updated_at ?? null,
    runs: (runs ?? []).map((run) => ({
      runId: run.run_id,
      stage: run.stage,
      outcome: run.outcome,
      score: Number(run.score),
      durationMs: Number(run.duration_ms),
      recordedAt: Number(run.recorded_at),
      eligible: Boolean(run.eligible),
      configuration: run.configuration,
    })),
  }
}

async function readProfile(connection, userId) {
  const [profiles] = await connection.execute(
    'SELECT display_name, highest_stage, total_coins, reputation, best_score, best_duration_ms, tutorial_version, updated_at FROM game_profiles WHERE user_id = ? LIMIT 1',
    [userId],
  )
  const [runs] = await connection.execute(
    'SELECT run_id, stage, outcome, score, duration_ms, recorded_at, eligible, configuration FROM game_run_records WHERE user_id = ? ORDER BY created_at DESC, id DESC LIMIT 50',
    [userId],
  )
  return profileFromRow(profiles[0], runs)
}

export async function getProfile(userId) {
  return readProfile(getPool(), userId)
}

export async function syncProfile(userId, profile, runs) {
  const connection = await getPool().getConnection()
  try {
    await connection.beginTransaction()
    await connection.execute(
      `INSERT INTO game_profiles
        (user_id, display_name, highest_stage, total_coins, reputation, best_score, best_duration_ms, tutorial_version)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
        display_name = IF(VALUES(display_name) <> '', VALUES(display_name), display_name),
        highest_stage = GREATEST(highest_stage, VALUES(highest_stage)),
        total_coins = GREATEST(total_coins, VALUES(total_coins)),
        reputation = VALUES(reputation),
        best_score = GREATEST(best_score, VALUES(best_score)),
        best_duration_ms = CASE
          WHEN VALUES(best_duration_ms) IS NULL THEN best_duration_ms
          WHEN best_duration_ms IS NULL THEN VALUES(best_duration_ms)
          ELSE LEAST(best_duration_ms, VALUES(best_duration_ms))
        END,
        tutorial_version = GREATEST(tutorial_version, VALUES(tutorial_version)),
        updated_at = CURRENT_TIMESTAMP(3)`,
      [userId, profile.displayName, profile.highestStage, profile.totalCoins, profile.reputation, profile.bestScore, profile.bestDurationMs, profile.tutorialVersion],
    )
    for (const run of runs) {
      await connection.execute(
        `INSERT INTO game_run_records
          (user_id, run_id, stage, outcome, score, duration_ms, recorded_at, eligible, configuration)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE run_id = run_id`,
        [userId, run.runId, run.stage, run.outcome, run.score, run.durationMs, run.recordedAt, run.eligible ? 1 : 0, run.configuration],
      )
    }
    await connection.execute(
      `DELETE FROM game_run_records
       WHERE user_id = ? AND id NOT IN (
         SELECT id FROM (
           SELECT id FROM game_run_records WHERE user_id = ? ORDER BY created_at DESC, id DESC LIMIT 50
         ) AS recent_runs
       )`,
      [userId, userId],
    )
    const current = await readProfile(connection, userId)
    await connection.commit()
    return current
  } catch (error) {
    await connection.rollback()
    throw error
  } finally {
    connection.release()
  }
}

export async function closePool() {
  if (pool) {
    const active = pool
    pool = undefined
    await active.end()
  }
}
