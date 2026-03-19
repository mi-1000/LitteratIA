<script lang="ts">
  import { Button } from '$components/dsfr'
  import Selector from '$components/Selector.svelte'
  import {
      APINegativeReactions,
      APIPositiveReactions,
      APIGeneralReactions,
      type APIReactionPref
  } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { noop } from '$lib/utils/commons'

  export interface LikePanelProps {
    id: string
    show?: boolean
    kind?: 'like' | 'dislike' | 'neutral'
    model: string
    selection: APIReactionPref[]
    comment?: string
    disabled?: boolean
    mode?: 'react' | 'vote'
    onSelectionChange?: (selection: APIReactionPref[]) => void
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
    mode = 'react',
    onSelectionChange = noop,
    onCommentChange = noop
  }: LikePanelProps = $props()

  let like_panel: HTMLDivElement
  let hasBeenShown = $state(false)

  const reactions = {
    like: {
      label: m['vote.choices.positive.question'](),
      icon: 'i-bi-hand-thumbs-up-fill',
      choices: APIPositiveReactions.map((value) => ({
        value,
        label: m[`vote.choices.positive.${value}`]()
      })) as { value: APIReactionPref; label: string }[]
    },
    dislike: {
      label: m['vote.choices.negative.question'](),
      icon: 'i-bi-hand-thumbs-down-fill',
      choices: APINegativeReactions.map((value) => ({
        value,
        label: m[`vote.choices.negative.${value}`]()
      })) as { value: APIReactionPref; label: string }[]
    },
     neutral: {
      label: m['vote.choices.neutral.question'](),
      icon: 'i-bi-emoji-neutral-fill',
      choices: APIGeneralReactions.map((value) => ({
        value,
        label: m[`vote.choices.neutral.${value}`]()
      })) as { value: APIReactionPref; label: string }[]
    }
  }
  const reaction = $derived(reactions[kind])

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
  <p class="me-3! {mode === 'vote' ? 'mt-1! mb-0!' : 'mb-3!'} flex items-center">
    <i class="{reaction.icon} block text-lg" style="color: {kind === 'like' ? 'var(--cg-green)' : '#e1000f'}"></i>
    <span
      class="ms-2 font-bold text-dark-grey md:text-base text-[14px]"
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
    containerClass="flex flex-wrap gap-3"
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
</div>

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
                  placeholder={m['vote.comment.placeholder']({ model: model.toUpperCase() })}
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
                  class="mt-4! mb-2! mx-auto! block! btn-color"
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
    transition: border-color 0.3s, color 0.3s, background 0.3s;
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
    padding: calc(0.375rem - 1px) calc(0.75rem - 1px);
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
</style>
