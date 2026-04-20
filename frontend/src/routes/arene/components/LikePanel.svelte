<script lang="ts">
  import { browser } from '$app/environment'
  import { Button, Modal } from '$components/dsfr'
  import Selector from '$components/Selector.svelte'
  import {
    APIDetailReactionGroups,
    APIGeneralReactions,
    APINegativeReactions,
    APIPositiveReactions,
    type APIDetailReactionGroup,
    type APIDetailReactionPref,
    type APIVoteReactionPref
  } from '$lib/chatService.svelte'
  import { useLocalStorage } from '$lib/helpers/useLocalStorage.svelte'
  import { m } from '$lib/i18n/messages'
  import { noop } from '$lib/utils/commons'
  import { tick } from 'svelte'

  type PanelReactionPref = APIDetailReactionPref | APIVoteReactionPref

  export interface LikePanelProps {
    id: string
    show?: boolean
    kind?: 'like' | 'dislike' | 'neutral'
    model: string
    selection: PanelReactionPref[]
    comment?: string
    disabled?: boolean
    showTooltip?: boolean
    mode?: 'react' | 'vote' | 'detail'
    onSelectionChange?: (selection: PanelReactionPref[]) => void
    onCommentChange?: (comment: string) => void
  }

  let {
    id,
    show = true,
    kind = 'neutral',
    model,
    selection = $bindable([]),
    comment = $bindable(''),
    disabled = false,
    showTooltip = browser ? window.matchMedia('(pointer: coarse)').matches : true, // Show tooltip on touch devices by default
    mode = 'react',
    onSelectionChange = noop,
    onCommentChange = noop
  }: LikePanelProps = $props()

  let like_panel: HTMLDivElement
  let hasBeenShown = $state(false)
  let helpContent = $state<{ title: string, description: string } | null>(null);

  async function openHelp(choice: ReactionChoice) {
    helpContent = { title: choice.label, description: choice.description ?? '' };

    await tick()

    const dialog = document.getElementById('label-tooltip-modal');
    // @ts-expect-error - DSFR is globally available
    if (dialog && window.dsfr) {
      // @ts-expect-error - DSFR is globally available
      window.dsfr(dialog).modal.disclose()
    }
  }

  const LABEL_SEED_STORAGE_KEY = 'litteratia:reaction-label-seed'
  const initialSeed = browser ? Math.floor(Math.random() * 2147483647) + 1 : 1
  const labelSeed = useLocalStorage<number>(LABEL_SEED_STORAGE_KEY, initialSeed, (value) =>
    Number.isInteger(value) && value > 0 ? value : initialSeed
  )

  type MessageGetter = () => string
  const messageDictionary = m as unknown as Record<string, MessageGetter>
  const t = (key: string): string => messageDictionary[key]?.() ?? key

  type ReactionChoice = {
    value: PanelReactionPref
    label: string
    description?: string
  }

  function seededRandom(seed: number) {
    /**
     * @link{https://github.com/cprosche/mulberry32}
    */
    return () => {
      let t = (seed += 0x6d2b79f5)
      t = Math.imul(t ^ (t >>> 15), t | 1)
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296
    }
  }

  function shuffleWithSeed<T>(items: T[], seed: number): T[] {
    const result = [...items]
    const random = seededRandom(seed)

    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(random() * (i + 1))
      ;[result[i], result[j]] = [result[j], result[i]]
    }

    return result
  }

  type DetailGroup = {
    id: APIDetailReactionGroup
    label: string
    description: string
    choices: { value: APIDetailReactionPref; label: string; description: string }[]
  }

  const detailReactionGroups = $derived.by<DetailGroup[]>(() => {
    const seed = labelSeed.value
    const shuffledGroups = shuffleWithSeed([...APIDetailReactionGroups], seed)

    // We shuffle both the order groups and labels within groups to mitigate position bias across users, but keep the order consistent across sessions for a same user
    return shuffledGroups.map((group, groupIndex) => ({
      id: group.id,
      label: t(`vote.choices.neutral.categories.${group.id}`),
      choices: shuffleWithSeed([...group.reactions], seed + groupIndex + 1).map((value) => ({
        value,
        label: t(`vote.choices.neutral.${value}.label`),
        description: t(`vote.choices.neutral.${value}.description`)
      }))
    }))
  })

  const reactions = {
    like: {
      // TODO fix: only neutral labels still exist, others should be removed, but this introduces breaking changes
      label: m['vote.choices.positive.question'](),
      icon: 'i-bi-hand-thumbs-up-fill',
      choices: APIPositiveReactions.map((value) => ({
        value,
        label: m[`vote.choices.positive.${value}`]()
      })) as ReactionChoice[]
    },
    dislike: {
      label: m['vote.choices.negative.question'](),
      icon: 'i-bi-hand-thumbs-down-fill',
      choices: APINegativeReactions.map((value) => ({
        value,
        label: m[`vote.choices.negative.${value}`]()
      })) as ReactionChoice[]
    },
    neutral: {
      label: m['vote.choices.neutral.question'](),
      icon: 'i-bi-question-circle-fill',
      choices: APIGeneralReactions.map((value) => ({
        value,
        label: t(`vote.choices.neutral.${value}.label`),
        description: t(`vote.choices.neutral.${value}.description`)
      })) as ReactionChoice[]
    }
  }
  const reaction = $derived(reactions[kind] ?? reactions.neutral)

  function scrollIntoViewWithOffset(element: HTMLElement, offset: number) {
    // For offset 0 just consider a footer of 100px (really is 114px)
    offset = Math.max(100, offset || 0)
    const rect = element.getBoundingClientRect()
    const viewportHeight = window.visualViewport?.height || window.innerHeight

    const isVisible = rect.bottom <= viewportHeight - offset

    if (!isVisible) {
      // this not enough because margins so let's just add some extra
      // const scrollTop = window.scrollY + rect.height;
      const scrollTop = window.scrollY + rect.height + offset
      window.scrollTo({ top: scrollTop, behavior: 'smooth' })
    }
  }

  function checkVisibility() {
    if (!show || hasBeenShown || !like_panel) return

    const footer = document.getElementById('send-area')
    const footerHeight = footer ? footer.offsetHeight : 0
    const rect = like_panel.getBoundingClientRect()
    const appeared = !like_panel.classList.contains('hidden') && rect.height > 0

    if (appeared) {
      scrollIntoViewWithOffset(like_panel, footerHeight)
      hasBeenShown = true
    } else {
      requestAnimationFrame(checkVisibility)
    }
  }

  $effect(() => {
    if (show && !hasBeenShown && like_panel) {
      checkVisibility()
    } else if (!show) {
      hasBeenShown = false
    }
  })
</script>

<div
  bind:this={like_panel}
  class="like-panel"
  class:hidden={show === false}
  class:flex={mode === 'vote'}
>
  {#if mode === 'detail'}
    <div class="w-full">
      <p class="mb-4! font-bold text-dark-grey md:text-base text-center text-[14px]">
        {m['vote.choices.neutral.question']()}
      </p>

      <div class="flex flex-col w-full xl:w-2/3 max-w-[600px] mx-auto gap-10 md:grid md:grid-cols-3 md:gap-0 md:justify-items-center">
        {#each detailReactionGroups as group (group.id)}
          <section class="flex flex-col items-center w-full md:items-start md:w-fit">
            <p class="mb-3! w-full md:text-left font-bold text-dark-grey text-sm text-center!">
              {group.label}
            </p>
            <div class="grid grid-cols-2 max-[340px]:grid-cols-1 gap-3 sm:flex sm:flex-row sm:justify-center md:flex-col w-fit">
              {#each group.choices as choice (choice.value)}
                <!-- svelte-ignore a11y_click_events_have_key_events -->
                <div
                  role="button"
                  tabindex="0"
                  class={[
                    'flex items-center min-w-0 justify-between w-full p-2 like-choice detail-like-choice',
                    selection.includes(choice.value) ? 'is-selected' : ''
                  ]}
                  title={!showTooltip ? choice.description : undefined}
                  onclick={() => {
                    if (disabled) return
                    if (selection.includes(choice.value)) {
                      selection = selection.filter((v) => v !== choice.value)
                    } else {
                      selection = [...selection, choice.value]
                    }
                    onSelectionChange(selection)
                  }}
                >
                  <span class="flex-1 min-w-0 text-center leading-tight tracking-tight wrap-break-word hyphens-auto px-1 text-[14px] md:text-[15px] lg:text-[16px]">
                    {choice.label}
                  </span>
                  {#if showTooltip && choice.description}
                    <button
                      type="button"
                      title={m['words.detail']()}
                      class="i-bi-patch-question-fill text-gray transition-colors ml-1 h-4 w-4 shrink-0"
                      onclick={(e) => {
                        e.preventDefault()
                        e.stopPropagation() // Prevents from selecting the main button
                        openHelp(choice)
                      }}
                    >
                    </button>
                  {/if}
                </div>
              {/each}
            </div>
          </section>
        {/each}
      </div>
    </div>
  {:else}
    <p class="me-3! {mode === 'vote' ? 'mt-1! mb-0!' : 'mb-3!'} flex items-center justify-center">
      <i
        class="{reaction.icon} text-lg block"
        style="color: {kind === 'like'
          ? 'var(--cg-green)'
          : kind === 'neutral'
            ? 'var(--cg-grey)'
            : '#e1000f'}"
      ></i>
      <span
        class="ms-2 font-bold text-dark-grey md:text-base -translate-y-[0.75px] text-[14px]"
        class:sr-only={mode === 'vote'}
      >
        {reaction.label}
      </span>
    </p>
    <Selector
      id="{id}-selector"
      kind="checkbox"
      bind:value={selection}
      choices={reaction.choices}
      multiple
      {disabled}
      containerClass="flex flex-wrap gap-3 justify-center"
      choiceClass="like-choice"
      onChange={onSelectionChange}
    >
      {#snippet option(choice, props, _input)}
        <button
          type="button"
          {disabled}
          class={[props.class, selection.includes(choice.value) ? 'is-selected' : '']}
          onclick={() => {
            if (disabled) return
            if (selection.includes(choice.value)) {
              selection = selection.filter((v) => v !== choice.value)
            } else {
              selection = [...selection, choice.value]
            }
            onSelectionChange(selection)
          }}
        >
          {choice.label}
        </button>
      {/snippet}
      {#snippet extra(props)}
        {#if mode === 'react'}
          <button
            {disabled}
            class={[props.class, comment !== '' ? 'is-selected' : '']}
            data-fr-opened="false"
            aria-controls="{id}-modal"
            onclick={() => {
              // Focus textarea once DSFR modal finishes opening
              setTimeout(() => {
                document.querySelector<HTMLTextAreaElement>(`#${id}-modal textarea`)?.focus()
              }, 400)
            }}
          >
            {m['vote.choices.other']()}
          </button>
        {/if}
      {/snippet}
    </Selector>
  {/if}
</div>

{#if helpContent}
  <Modal
    id="label-tooltip-modal"
    titleId="label-tooltip-modal-title"
    sizeClass="fr-col-12 fr-col-md-6" 
    onClose={() => helpContent = null}
  >
    <h1 id="label-tooltip-modal-title" class="fr-modal__title mb-4">
      {helpContent.title}
    </h1>
    <p class="text-gray leading-relaxed">
      {helpContent.description}
    </p>
  </Modal>
{/if}

<!-- Weird way to catch the comment if not validated but modal closed -->
{#if mode === 'react'}
  <dialog
    aria-labelledby="{id}-modal-label"
    id="{id}-modal"
    class="fr-modal"
    onblur={() => onCommentChange(comment)}
    onkeydown={(e) => {
      if (e.key === 'Escape') {
        onCommentChange(comment)
      }
    }}
  >
    <div class="fr-container fr-container--fluid fr-container-md">
      <div class="fr-grid-row fr-grid-row--center">
        <div class="fr-col-12 fr-col-md-8 fr-col-lg-6">
          <div class="fr-modal__body rounded-xl">
            <div class="fr-modal__header">
              <Button
                variant="tertiary-no-outline"
                text={m['words.close']()}
                title={m['closeModal']()}
                aria-controls="{id}-modal"
                class="fr-btn--close"
                onclick={() => onCommentChange(comment)}
              />
            </div>
            <div class="fr-modal__content">
              <p id="{id}-modal-label" class="modal-title">{m['vote.comment.add']()}</p>
              <div>
                <textarea
                  placeholder={model === 'both_equal'
                    ? m['vote.comment.placeholder_both_equal']()
                    : m['vote.comment.placeholder']({ model: model.toUpperCase() })}
                  class="fr-input"
                  rows="4"
                  bind:value={comment}
                  onkeydown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault()
                      onCommentChange(comment)
                      const dialog = document.getElementById(`${id}-modal`)
                      // @ts-expect-error - DSFR is globally available
                      if (dialog) window.dsfr(dialog).modal.conceal()
                    } else if (e.key === 'Escape') {
                      onCommentChange(comment)
                      const dialog = document.getElementById(`${id}-modal`)
                      // @ts-expect-error - DSFR is globally available
                      if (dialog) window.dsfr(dialog).modal.conceal()
                    }
                  }}
                  enterkeyhint="send"
                ></textarea>
                <Button
                  aria-controls="{id}-modal"
                  class="mt-4! mb-2! btn-color mx-auto! block!"
                  onclick={() => onCommentChange(comment)}
                >
                  {m['words.save']()}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </dialog>
{/if}

<style>
  .modal-title {
    font-weight: 700;
    font-size: 1.1em;
  }

  :global(.like-choice) {
    display: inline-flex;
    align-items: center;
    padding: 0.375rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 500;
    border-radius: 0.5rem;
    border: 1px solid var(--border-default-grey);
    background: var(--background-default-grey);
    color: var(--text-mention-grey);
    cursor: pointer;
    transition:
      border-color 0.3s,
      color 0.3s,
      background 0.3s;
    margin: 0;
    user-select: none;
  }

  :global(.like-choice:hover) {
    border-color: var(--text-action-high-blue-france);
    color: var(--text-action-high-blue-france);
  }

  :global(.like-choice.is-selected) {
    border-color: var(--blue-france-main-525);
    background: var(--blue-france-975-75);
    color: var(--blue-france-main-525);
    font-weight: 600;
    border-width: 2px;
  }

  :global(.like-choice.is-selected:active) {
    background: var(--hover-tint, var(--blue-france-975-75));
  }

  :global(.like-choice:focus-visible) {
    outline: 2px solid var(--outline-color);
    outline-offset: 2px;
  }

  :global(.like-choice:disabled) {
    opacity: 0.5;
    cursor: not-allowed;
  }

  :global(.detail-like-choice) {
    min-width: fit-content;
  }
</style>
