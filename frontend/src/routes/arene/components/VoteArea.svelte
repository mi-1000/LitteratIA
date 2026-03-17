<script lang="ts">
  import { Button } from '$components/dsfr'
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { VoteData } from '$lib/chatService.svelte'
  import { arena } from '$lib/chatService.svelte'
  import { scrollTo } from '$lib/helpers/attachments'
  import { m } from '$lib/i18n/messages'
  import { getModelsContext } from '$lib/models'
  import { LikePanel, VoteRadioGroup } from '.'

  let {
    value: form = $bindable(),
    disabled = false,
    showModelName = false,
    invertModelLabels = false,
  }: {
    value: VoteData
    disabled?: boolean
    showModelName?: boolean | 'showA' | 'showB'
    invertModelLabels?: boolean
  } = $props()

  let showComments = $state(false)

  function prettifyModelId(id: string) {
    return id.replace(/[-_]+/g, ' ').replace(/(?:^|\s)\S/g, (s) => s.toUpperCase())
  }

  function splitModelId(id: string) {
    const s = String(id || '')
    const parts = s.split('/')
    if (parts.length >= 2) {
      const provider = parts[0]
      const model = parts.slice(1).join('/')
      return { provider, model }
    }
    return { provider: '', model: s }
  }

  function escapeHtml(input: string) {
    return String(input)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\"/g, '&quot;')
      .replace(/'/g, '&#39;')
  }

  function getModelPartsFor(side: 'a' | 'b') {
    if (!shouldShowFor(side)) return { provider: '', model: m['chatbot.modelAnon']({ side: side.toUpperCase() }) }
    try {
      const map = (arena as any).chat?.model_map
      const sideKey = side.toLowerCase()
      if (map && map[sideKey]) {
        const modelId = map[sideKey]
        try {
          const ctx = getModelsContext()
          if (ctx && ctx.models) {
            const found = ctx.models.find((mm: any) => mm.id === modelId || mm.simple_name === modelId)
            if (found) {
              const provider = found.organisation ? String(found.organisation) : ''
              const model = String(found.simple_name || modelId)
              return { provider, model }
            }
          }
        } catch (e) {
          // ignore
        }
        return splitModelId(prettifyModelId(modelId))
      }
    } catch (e) {
      // ignore
    }

    try {
      const fn = (m as any)[`models.names.${side}`]
      if (typeof fn === 'function') {
        const v = fn()
        if (v && v.toString().trim() !== '') return splitModelId(String(v))
      }
    } catch (e) {
      // ignore
    }

    return splitModelId(prettifyModelId(side))
  }

  function getModelHtmlFor(side: 'a' | 'b') {
    const parts = getModelPartsFor(side)
    const prov = parts.provider ? `<span class="provider-name">${escapeHtml(parts.provider)}/</span>` : ''
    const model = escapeHtml(parts.model)
    if (prov) return `${prov}${model}`
    return model
  }

  function shouldShowFor(side: 'a' | 'b' | string) {
    if (showModelName === true) return true
    if (showModelName === 'showA' && side === 'a') return true
    if (showModelName === 'showB' && side === 'b') return true
    return false
  }
</script>

<div id="vote-area" class="fr-container py-7 md:py-20" {@attach scrollTo}>
  <div class="text-center">
    <h4 class="fr-h6 mb-2!">{m['vote.title']()}</h4>
    <p class="fr-text--sm text-grey">
      {#if showModelName}
        {m['vote.introC']()}
      {:else}
        {m['vote.introA']()}<br />
        {m['vote.introB']()}
      {/if}
    </p>
  </div>

  <VoteRadioGroup bind:value={form.selected} {disabled} {showModelName} {invertModelLabels} />

  {#if form.selected}
    <div class="mt-11 gap-6 md:flex-row flex flex-col">
      {#each ['a', 'b'] as const as model (model)}
        {@const displaySide = invertModelLabels ? (model === 'a' ? 'b' : 'a') : model}
        <div
          class="cg-border gap-4 rounded-lg! bg-white p-4 md:rounded-lg md:px-6 md:py-8 flex w-full flex-col"
        >
          <div class="flex items-center">
                <div class="c-bot-disk-{model}"></div>
                <p class="ms-1! mb-0! font-bold">
                    {#if shouldShowFor(displaySide)}
                      {@html getModelHtmlFor(displaySide)}
                    {:else}
                      {m['chatbot.modelAnon']({ side: model.toUpperCase() })}
                    {/if}
                </p>
          </div>

          <p class="mb-0! font-bold">{m['vote.qualify.question']()}</p>

          <LikePanel
            id="model-{model}"
            show={true}
            kind="like"
            mode="vote"
            model={model.toUpperCase()}
            bind:selection={form[model].like}
            {disabled}
          />
          <LikePanel
            id="model-{model}"
            show={true}
            kind="dislike"
            mode="vote"
            model={model.toUpperCase()}
            bind:selection={form[model].dislike}
            {disabled}
          />

          {#if showComments}
            <TextPrompt
              id="comment-{model}"
              bind:value={form[model].comment}
              label={m['vote.qualify.question']()}
              placeholder={m['vote.qualify.placeholder']({ model: model.toUpperCase() })}
              rows={3}
              {disabled}
            />
          {/if}
        </div>
      {/each}
    </div>

    {#if !showComments}
      <div class="mt-4 text-center">
        <Button
          variant="secondary"
          text={m['vote.qualify.addDetails']()}
          {disabled}
          onclick={() => (showComments = true)}
        />
      </div>
    {/if}
  {/if}
</div>

<style>
  :global(#vote-area:has(+ #send-area)) {
    min-height: calc(100vh - var(--second-header-size) - var(--footer-size) + 2px);
    scroll-margin-top: calc(var(--second-header-size));
  }
</style>
