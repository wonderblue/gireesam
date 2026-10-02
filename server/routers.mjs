import { z } from 'zod'
import { router, protectedProcedure } from './webdev-adapter.mjs'
import { getProfile, syncProfile } from './db.mjs'
import { sendOwnerAlert } from './owner-alerts.mjs'

const profileInput = z.object({
	displayName: z.string().trim().max(96).default(''),
	highestStage: z.number().int().min(0).max(99),
	totalCoins: z.number().int().min(0).max(100000000),
	reputation: z.number().int().min(-100).max(100),
	bestScore: z.number().int().min(0).max(100000000),
	bestDurationMs: z.number().int().min(0).max(864000000).nullable().default(null),
	tutorialVersion: z.number().int().min(0).max(1000),
})

const runInput = z.object({
	runId: z.string().regex(/^[A-Za-z0-9._:-]{1,100}$/),
	stage: z.string().trim().min(1).max(80),
	outcome: z.enum(['victory', 'defeat']),
	score: z.number().int().min(0).max(100000000),
	durationMs: z.number().int().min(0).max(864000000),
	recordedAt: z.number().int().min(0).max(2147483647),
	eligible: z.boolean(),
	configuration: z.string().regex(/^[a-f0-9]{1,128}$/),
})

export const gameRouter = router({
  profile: protectedProcedure.query(async ({ ctx }) => {
    const profile = await getProfile(ctx.user.id)
    sendOwnerAlert('account_session_seen', { player: profile.displayName || ctx.user.name || 'Unknown player' })
    return profile
  }),
  sync: protectedProcedure.input(z.object({
		profile: profileInput,
		runs: z.array(runInput).max(10).default([]),
	})).mutation(async ({ ctx, input }) => {
    try {
      const saved = await syncProfile(ctx.user.id, input.profile, input.runs)
      for (const run of input.runs) {
        if (run.outcome === 'victory' || run.outcome === 'defeat') {
          sendOwnerAlert(run.outcome === 'victory' ? 'run_completed' : 'run_defeated', {
            player: input.profile.displayName || ctx.user.name || 'Unknown player',
            stage: run.stage,
            outcome: run.outcome,
            score: run.score,
            durationMs: run.durationMs,
            eligible: run.eligible,
          })
        }
      }
      return saved
    } catch (error) {
      sendOwnerAlert('cloud_save_failed', {
        player: input.profile.displayName || ctx.user.name || 'Unknown player',
        error: error instanceof Error ? error.message : 'unknown_error',
      })
      throw error
    }
	}),
})
