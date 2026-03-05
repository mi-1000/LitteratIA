<script lang="ts">
  import IconButton from '$components/IconButton.svelte'
  import { m } from '$lib/i18n/messages'

  export interface LikeDislikeProps {
    liked: boolean | null
    onChange: (liked: boolean | null) => void
    disabled?: boolean
  }
  let { liked = $bindable(), onChange, disabled = false }: LikeDislikeProps = $props()
</script>

<IconButton
  {disabled}
  border={true}
  icon={disabled ? 'i-bi-hand-thumbs-up' : liked === true ? 'i-bi-hand-thumbs-up-fill' : 'i-bi-hand-thumbs-up'}
  label={m[`vote.like.${liked === true ? 'selectedLabel' : 'label'}`]()}
  highlight={liked === true}
  onclick={() => {
    liked = liked === true ? null : true
    onChange(liked)
  }}
/>

<IconButton
  {disabled}
  border={true}
  icon={disabled ? 'i-bi-hand-thumbs-down' : liked === false ? 'i-bi-hand-thumbs-down-fill' : 'i-bi-hand-thumbs-down'}
  label={m[`vote.dislike.${liked === false ? 'selectedLabel' : 'label'}`]()}
  highlight={liked === false}
  onclick={() => {
    liked = liked === false ? null : false
    onChange(liked)
  }}
/>
