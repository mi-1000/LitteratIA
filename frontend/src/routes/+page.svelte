<script lang="ts">
  import { Button, Icon, Tooltip } from '$components/dsfr'
  import Header from '$components/header/Header.svelte'
  import SeoHead from '$components/SEOHead.svelte'
  import { arena, modeInfos } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { TOSModal, ViewChat, ViewPrompt } from './arene/components'

  const mode = $derived(arena.mode ? modeInfos.find((mode) => mode.value === arena.mode)! : null)
  let toggled = $state(false)

  // Compute second header height for autoscrolling
  let secondHeader = $state<HTMLElement>()
  let secondHeaderSize = $derived<number>(secondHeader?.offsetHeight ?? 0)

  function onResize() {
    secondHeaderSize = secondHeader ? secondHeader.offsetHeight : 0
  }
</script>

<svelte:window onresize={onResize} />

<SeoHead title={m['seo.titles.arene']()} />

<TOSModal />

<Header
  hideNavigation
  hideDiscussBtn
  hideVoteGauge//={arena.currentScreen === 'prompt'}
  small
/>

{#snippet desc()}
  <p class="mt-2! mb-0! text-sm! leading-normal! text-grey md:mt-0!">
    {#if arena.chat.step == 1}
      {m['header.chatbot.stepOne.description']()}
    {:else}
      {m['header.chatbot.stepTwo.description']()}
    {/if}
  </p>
{/snippet}

{#snippet extra()}
  {#if arena.chat.step == 1}
    <div
      class="cg-border rounded-lg! mt-2 bg-white py-1 text-sm md:mt-0 md:py-3 w-full border-dashed! text-center" id="chatting-mode-indicator"
    >
      <Icon icon={mode!.icon} size="sm" class="text-primary" />
      &nbsp;<strong>{mode!.title}</strong>
      &nbsp;<Tooltip id="mode-desc" text={mode!.description} size="xs" />
    </div>
  {:else}
    <div class="md:block hidden text-right">
      <Button
        icon="edit-line"
        text={m['header.chatbot.newDiscussion']()}
        class="md:w-auto! w-full! btn-color"
        onclick={() => (window.location.href = '/')}
      />
    </div>
  {/if}
{/snippet}

<main class="bg-very-light-grey relative" style="--second-header-size: {secondHeaderSize}px;">
  {#if arena.currentScreen === 'prompt'}
    <ViewPrompt />
  {:else}
    <ViewChat />
  {/if}
</main>
