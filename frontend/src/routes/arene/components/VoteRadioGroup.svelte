  <script lang="ts">
    import type { BotChoice } from '$lib/chatService.svelte'
    import { arena } from '$lib/chatService.svelte'
    import { m } from '$lib/i18n/messages'
    import { getModelsContext } from '$lib/models'

    export interface VoteAreaProps {
      value?: BotChoice
      disabled?: boolean
      showModelName?: boolean | 'showA' | 'showB'
    }

    let { value: selected = $bindable(), disabled = false, showModelName = false, invertModelLabels = false }: VoteAreaProps & { invertModelLabels?: boolean } = $props()

    function shouldShowFor(modelSide: 'a' | 'b' | string) {
      if (showModelName === true) return true
      if (showModelName === 'showA' && modelSide === 'a') return true
      if (showModelName === 'showB' && modelSide === 'b') return true
      return false
    }

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
      // `side` is the logical model side to display (already adjusted by caller for inversion)
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

    const choices = ['a', 'both_equal', 'b'] as const
  </script>

  <fieldset id="vote-cards" aria-labelledby="vote-cards-legend" class="flex flex-col md:flex-row items-center justify-center">
    <legend class="sr-only" id="vote-cards-legend">{m['vote.title']()}</legend>

    <div class="flex flex-col sm:flex-row gap-3 sm:justify-center md:gap-5">
      {#each choices as value (value)}
        {@const displaySide = value === 'both_equal' ? 'both_equal' : (invertModelLabels ? (value === 'a' ? 'b' : 'a') : value)}
        <div class="h-full self-center">
          <button
            type="button"
            class="cg-border flex flex-row items-center justify-center gap-2 px-3 py-4 text-center font-medium transition-all md:rounded-[56px]! btn-color btn-vote-models"
            aria-pressed={selected === value}
            disabled={disabled}
            onclick={() => { if (!disabled) selected = value }}
          >
            {#if value === 'both_equal'}
              <svg
                width="26"
                height="26"
                viewBox="0 0 26 26"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                class="shrink-0"
              >
                <rect x="0.5" y="0.5" width="25" height="25" rx="12.5" fill="white" />
                <rect x="0.5" y="0.5" width="25" height="25" rx="12.5" stroke="#E5E5E5" />
                <path d="M20 9H6V11H20V9ZM20 15H6V17H20V15Z" fill="#1A1A1A" />
              </svg>
            {:else}
              <div class="c-bot-disk-{value} shrink-0"></div>
            {/if}
            <span class="leading-tight">
              {#if value !== 'both_equal' && shouldShowFor(displaySide)}
                {@html getModelHtmlFor(displaySide)}
              {:else if value !== 'both_equal'}
                {m['chatbot.modelAnon']({ side: value.toUpperCase() })}
              {:else}
                {m['vote.bothEqual']()}
              {/if}
            </span>
          </button>
        </div>
      {/each}
    </div>
  </fieldset>

  <style>
    input:focus + label {
      outline: 2px solid var(--outline-color);
      outline-offset: 2px;
    }
    input:checked + label {
      border: 2px solid var(--blue-france-main-525);
      background: var(--blue-france-975-75);
      color: var(--blue-france-main-525);
    }
    
    .c-bot-disk-a,
    .c-bot-disk-b,
    .btn-color svg {
      border-radius: 50%;
      border: none;
      box-sizing: border-box;
    }

    .btn-vote-models[aria-pressed="true"] .c-bot-disk-a,
    .btn-vote-models[aria-pressed="true"] .c-bot-disk-b { 
      border: 1px solid var(--border-default-grey) !important;
    }
  </style>
