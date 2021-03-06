Captcha.fixes =
  css: '''
    .rc-imageselect-target > .rc-imageselect-tile > img:focus {
      outline: 2px solid #4a90e2;
    }
    .rc-button-default:focus {
      box-shadow: inset 0 0 0 2px #0063d6;
    }
  '''

  init: ->
    switch location.pathname.split('/')[3]
      when 'anchor' then @initMain()
      when 'frame'  then @initPopup()

  initMain: ->
    $.onExists d.body, '#recaptcha-anchor', true, (checkbox) ->
      focus = ->
        if d.hasFocus() and d.activeElement isnt checkbox
          checkbox.focus()
      focus()
      $.on window, 'focus', ->
        $.queueTask focus

  initPopup: ->
    $.addStyle @css
    @fixImages()
    new MutationObserver(=> @fixImages()).observe d.body, {childList: true, subtree: true}
    $.on d, 'keydown', @keybinds.bind(@)

  fixImages: ->
    return unless (@images = $$ '.rc-imageselect-target > .rc-imageselect-tile > img').length
    focus = @images[0].tabIndex isnt 0
    for img in @images
      img.tabIndex = 0
    if focus
      $.queueTask => @focusImage()

  focusImage: ->
    # XXX Image is not focusable at first in Firefox; to be refactored when I figure out why.
    img = @images[0]
    $.asap ->
      return true unless doc.contains img
      img.focus()
      d.activeElement is img
    , ->

  keybinds: (e) ->
    return unless @images and doc.contains(@images[0]) and d.activeElement
    reload = $.id 'recaptcha-reload-button'
    verify = $.id 'recaptcha-verify-button'
    x = @images.indexOf d.activeElement
    if x < 0
      return unless $('.rc-controls').contains d.activeElement
      x = if d.activeElement is verify then 11 else 9
    return unless dx = {38: 9, 40: 3, 37: 11, 39: 1, 73: 9, 75: 3, 74: 11, 76: 1}[e.keyCode] # Up, Down, Left, Right, I, K, J, L
    x = (x + dx) % 12
    if x is 10
      x = if dx is 11 then 9 else 11
    (@images[x] or {9: reload, 11: verify}[x]).focus()
    e.preventDefault()
    e.stopPropagation()
