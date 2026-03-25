<script lang="ts">
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { APIReactionData, BotChoice } from '$lib/chatService.svelte'
  import { APIGeneralReactions, postVoteGetReveal, updateReaction } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { LikePanel, StarRating, VoteRadioGroup } from '.'
  import { debounce } from 'lodash-es'

  let selected_model: BotChoice | undefined = $state(undefined)
  let rating: number = $state(0)
  let selection: (typeof APIGeneralReactions)[number][] = $state([])
  let comment: string = $state("")

  let { disabled = false }: { disabled?: boolean } = $props()

  $effect(() => {
    const _ = selected_model
    rating = 0
  })

  $effect(() => {
    const _ = rating
    selection = []
  })

  const saveVote = debounce(async () => {
    if (!selected_model) return

    const voteData: APIReactionData = {
      bot: selected_model,
      index: 1, // TODO Fix that
      value: comment,
      liked: true,
      prefs: selection
    }

    try {
      await updateReaction(voteData)
    } catch (err) {
      console.error("Failed to auto-save vote:", err)
    }
  }, 500) // Send updates to database at most once every 500ms

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
    <!-- Ensuite, étiquettes, puis finalement, zone de texte (réinitialiser si on change au-dessus) -->
    <!-- Basculer le bouton révéler à la fin de chaque formulaire -->
    <!-- Griser les formulaires précédents lorsqu'un nouveau message est envoyé -->
    <!-- Si un vote est fait pour la première fois depuis x messages, agréger et enregistrer tous les messages précédents dans la base de données pour l'entrée du vote -->
  {/if}
</div>
