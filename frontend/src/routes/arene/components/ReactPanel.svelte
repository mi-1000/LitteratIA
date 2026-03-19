<script lang="ts">
    import { LikePanel, StarRating, VoteRadioGroup } from '.'
    import { m } from '$lib/i18n/messages'
    import type { BotChoice } from '$lib/chatService.svelte'

    let selected_model: BotChoice | undefined = $state(undefined)
    let rating: number = $state(0)
    $effect(() => {
        const _ = selected_model
        rating = 0
    })
</script>

<div class="flex flex-col items-center justify-center">
    <div><VoteRadioGroup bind:value={selected_model} /></div>
    {#if selected_model !== undefined}
        <div class="mt-4">
            <StarRating bind:value={rating} selected_model={selected_model} />
        </div>
        {#if rating > 0}
            <div class="mt-4">
                <LikePanel
                    id="like-panel"
                    show={true}
                    model={selected_model}
                    selection={[]}
                    onSelectionChange={(sel) => console.log('Selected like reactions:', sel)}
                />
            </div>
        {/if}
        <!-- Ensuite, étiquettes, puis finalement, zone de texte -->
    {/if}
</div>
