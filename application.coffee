$(document).ready ->
  $(".playlist").addClass "closed hidden transition transition-height"
  $(".cover-picker").on "click", "a", (event) ->
    coverAnchor = @
    coverSelected = coverAnchor.parentNode
    coverActive = $(".cover-picker .active")
    albumSelected = coverAnchor.href.replace "#", ""
    indicatorPosition = (coverSelected.offsetLeft + (coverSelected.offsetWidth / 2) - 15)
    playlistHeight = $(".playlist-inner")[0].getBoundingClientRect().height

    togglePlaylistForAlbum = (album) =>
      isExpanding = $(".playlist").hasClass "closed"
      targetHeight = if isExpanding then 400 else 0

      if isExpanding
        $(".playlist").removeClass "hidden"
        $(".playlist-indicator").removeClass("hidden").css "left", indicatorPosition
      else
        $(".playlist").on "webkitTransitionEnd", ->
          $(".playlist-indicator").addClass "hidden"
          $(".playlist").addClass("hidden").off "webkitTransitionEnd"

      $(coverSelected).toggleClass "active"
      $(".playlist").toggleClass("closed expanded").height targetHeight

    switchPlaylistToAlbum = (album) ->
      $(coverActive).removeClass "active"
      $(coverSelected).addClass "active"
      $(".playlist-indicator").css "left", indicatorPosition

    if ($(coverActive).length is 0) or (coverSelected is coverActive[0])
      togglePlaylistForAlbum albumSelected
    else if $(coverActive).length > 0
      switchPlaylistToAlbum albumSelected

    coverAnchor.blur()
    event.preventDefault()

    canvas = document.getElementById "album-artwork"
    image = new Image
    image.src = coverAnchor.childNodes[0].src

    ColorTunes.launch image, canvas
