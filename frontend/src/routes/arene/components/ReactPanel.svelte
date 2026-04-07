<script lang="ts">
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { APIReactionData, BotChoice } from '$lib/chatService.svelte'
  import { APIGeneralReactions, updateReaction } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { debounce } from 'lodash-es'
  import { LikePanel, StarRating, VoteRadioGroup } from '.'
  import { getLocale } from '$lib/i18n/runtime'
  import { page } from '$app/state'

  export type Ratings = 0 | 1 | 2 | 3 | 4 | 5

  let selected_model: BotChoice | undefined = $state(undefined)
  let rating: Ratings = $state(0 as Ratings)
  let selection: (typeof APIGeneralReactions)[number][] = $state([])
  let comment: string = $state('')

  let { disabled = false, index }: { disabled?: boolean; index: number } = $props()

  $effect(() => {
    const _ = selected_model
    rating = 0 as Ratings
  })

  $effect(() => {
    const _ = rating
    selection = []
  })

  $effect(() => {
    const _ = selection
    comment = ''
  })

  const saveVote = debounce(async () => {
    if (!selected_model) return

    const voteData: APIReactionData = {
      bot: selected_model,
      index: index,
      value: comment,
      interface_lang: page.data?.locale || getLocale(),
      liked: rating !== undefined && (rating) > (3 as Ratings), // Consider ratings of 4 and 5 as "liked" -- this is legacy behaviour anyway
      comment: comment,
      rating: rating,
      prefs: selection
    }

    try {
      await updateReaction(voteData)
    } catch (err) {
      console.error('Failed to auto-save vote:', err)
    }
  }, 800) // Send updates to database at most once every 800ms

  $effect(() => {
    void selected_model
    void rating
    void selection
    void comment

    if (selected_model !== undefined) {
      saveVote()
    }
  })
</script>

<div class="flex flex-col items-center justify-center">
  <div><VoteRadioGroup bind:value={selected_model} {disabled} /></div>
  {#if selected_model !== undefined}
    <div class="mt-4">
      <StarRating bind:value={rating} {selected_model} {disabled} />
    </div>
    {#if rating > 0}
      <div class="mt-4">
        <LikePanel
          id="like-panel"
          show={true}
          model={selected_model}
          bind:selection
          mode="detail"
          {disabled}
        />
      </div>
      {#if selection.length > 0}
        <TextPrompt
          id="text-prompt"
          label={m['vote.elaborate']()}
          placeholder={selected_model === 'both_equal'
            ? m['vote.comment.placeholder_both_equal']()
            : m['vote.comment.placeholder']({ model: selected_model.toUpperCase() })}
          minRows={4}
          maxRows={4}
          class="mt-4"
          {disabled}
          bind:value={comment}
        />
      {/if}
    {/if}
  {/if}
</div>
