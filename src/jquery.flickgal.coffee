###

 jQuery flickGal 1.2.2

 Copyright (c) 2011 Soichi Takamura (http://stakam.net/jquery/flickgal/demo)

 Dual licensed under the MIT and GPL licenses:
 http://www.opensource.org/licenses/mit-license.php
 http://www.gnu.org/licenses/gpl.html

###


###
  init variables about browsers environment
###
BrowserType =
  WEBKIT: 0
  GECKO: 1
  MSIE: 2
  OPERA: 3
  OTHER: 4

userAgent = navigator.userAgent.toLowerCase()

currentBrowser =
  if userAgent.indexOf('webkit') >= 0
    BrowserType.WEBKIT
  else if userAgent.indexOf('gecko') >= 0
    BrowserType.GECKO
  else if userAgent.indexOf('msie') >= 0
    BrowserType.MSIE
  else if userAgent.indexOf('opera') >= 0
    BrowserType.OPERA
  else
    BrowserType.OTHER

isIOS = userAgent.indexOf('iphone') >= 0 or userAgent.indexOf('ipad') >= 0
isAndroid = userAgent.indexOf('android') >= 0
isMobile = isIOS or isAndroid

CSS_PREFIX =
  switch currentBrowser
    when BrowserType.WEBKIT
      '-webkit-'
    when BrowserType.GECKO
      '-moz-'
    when BrowserType.MSIE
      '-ms-'
    when BrowserType.OPERA
      '-o-'
    when BrowserType.OTHER
      ''

CSS_TRANSITION = CSS_PREFIX + 'transition'
CSS_TRANSFORM = CSS_PREFIX + 'transform'
CSS_TRANSFORM_ORIGIN = CSS_PREFIX + 'transform-origin'
TRANSLATE_PREFIX = if currentBrowser == BrowserType.WEBKIT then 'translate3d(' else 'translate('
TRANSLATE_SUFFIX = if currentBrowser == BrowserType.WEBKIT then 'px,0,0)' else 'px,0)'

EventType =
  # Original events triggered.
  FG_FLICKSTART: 'fg_flickstart'
  FG_FLICKEND: 'fg_flickend'
  FG_CHANGE: 'fg_change'

  # Native events.
  START: if isMobile then 'touchstart' else 'mousedown'
  END: if isMobile then 'touchend' else 'mouseup'
  MOVE: if isMobile then 'touchmove' else 'mousemove'
  TRANSITION_END:
    if currentBrowser == BrowserType.WEBKIT then 'webkitTransitionEnd'
    else if currentBrowser == BrowserType.OPERA then 'oTransitionEnd'
    else 'transitionend'
  ORIENTATION_CHAGE: 'orientationchange'
  CLICK: 'click'
  RESIZE: 'resize'

EventType.ORIENTATION_CHAGE = "#{EventType.ORIENTATION_CHAGE} #{EventType.RESIZE}"  if isAndroid  # XXX


###
  common function
###
getCssTranslateValue = (translateX) ->
  [ TRANSLATE_PREFIX, translateX, TRANSLATE_SUFFIX ].join ''


###
  implement plugin
###
window.jQuery.fn.flickGal = (options) ->

  ###
    option
  ###
  options = $.extend(
    infinitCarousel: false
    lockScroll: true
  , options)

  ###
    iterate each element in jQuery object
  ###
  this.each ->


    ###
      private variables
    ###
    $flickBox = $(this)
    $container = $('.container', $flickBox).css(overflow: 'hidden')
    $box = $('.containerInner', $container).css
      position: 'relative'
      overflow: 'hidden'
      top: 0
      left: 0
    $items = $('.item', $box).css
      float: 'left'
    itemLength = $items.length
    itemWidth = $items.outerWidth(true)
    boxWidth = itemWidth * itemLength
    boxHeight = $items.outerHeight(true)
    minLeft = 0
    maxLeft = ((itemWidth * itemLength) - itemWidth) * -1
    currentIndex = 0 # currently displayed index
    containerOffsetLeft = 0
    containerBaseX = 0


    ###
      private functions
    ###
    getGeckoTranslateX = ($elm) ->
      try
        translateX = window.parseInt(/(,.+?){3} (.+?)px/.exec($elm.css(CSS_TRANSFORM))[2])
        return if not window.isNaN(translateX) then translateX + containerOffsetLeft else 0
      0

    getTranslateX = ->
      if currentBrowser isnt BrowserType.GECKO
        $box.offset().left
      else getGeckoTranslateX($box)

    redefineLeftOffset = (e) ->
      containerOffsetLeft = $container.offset().left
      containerBaseX = ($container.innerWidth() - itemWidth) / 2
      moveTo currentIndex


    ###
      implement navigation
    ###
    $nav = $('.nav', $flickBox)
    $navA = $nav.find('a[href^=#]')
    $navChildren = $navA.parent()
    useNav = !!($nav.length and $navA.length and $navChildren.length)


    ###
      implement next/prev arrows
    ###
    $prev = $('.prev', $flickBox)
    $next = $('.next', $flickBox)
    useArrows = !!($prev.length and $next.length)
    if useArrows
      prevTappedHandler = ->
        currentIndex = if currentIndex > 0 then currentIndex - 1 else if options.infinitCarousel then itemLength - 1 else currentIndex
        moveTo currentIndex

      nextTappedHandler = ->
        currentIndex = if currentIndex < itemLength - 1 then currentIndex + 1 else if options.infinitCarousel then 0 else currentIndex
        moveTo currentIndex

      disableArrow = ->
        $prev.add($next).removeClass 'off'
        if currentIndex == 0
          $prev.addClass 'off'
        else $next.addClass 'off'  if currentIndex == itemLength - 1


    ###
      implement core event handling
    ###
    startX = 0
    endX = 0
    startTime = 0
    startLeft = 0

    # Closer scope chain to refer, faster (maybe..).
    STATE =
      IS_MOVING: 1
      IS_EDGE:   2
      IS_FIRST:  4
      IS_LAST:   8
    state = 0

    touchHandler = (e) ->
      touch = if isMobile then e.touches[0] else e
      switch e.type

        when EventType.MOVE
          e.preventDefault()  if options.lockScroll
          if state & STATE.IS_MOVING
            diffX = touch.pageX - startX
            if state & STATE.IS_EDGE and
              (((state & STATE.IS_FIRST) && diffX > 0) or
               ((state & STATE.IS_LAST)  && diffX < 0))
              diffX = diffX / 2
            $box.css CSS_TRANSFORM, getCssTranslateValue(containerBaseX + startLeft + diffX)

        when EventType.START
          e.preventDefault()  unless isMobile
          state |= STATE.IS_MOVING
          state |= STATE.IS_FIRST  if currentIndex is 0
          state |= STATE.IS_LAST   if currentIndex is itemLength - 1
          state |= STATE.IS_EDGE   if state & STATE.IS_FIRST or state & STATE.IS_LAST
          startTime = (new Date()).getTime()
          startX = if isMobile then touch.pageX else e.clientX
          startLeft = getTranslateX() - containerOffsetLeft - containerBaseX
          $flickBox.trigger(EventType.FG_FLICKSTART, [currentIndex])
          $box.removeClass('moving').css CSS_TRANSFORM, getCssTranslateValue(containerBaseX + startLeft)  if $box.hasClass('moving')

        when EventType.END
          startLeft = 0
          state = 0 #reset
          endX = if isMobile then e.changedTouches[0].pageX else e.clientX
          index = calcNextIndex_()
          $flickBox.trigger(EventType.FG_FLICKEND, [index])
          moveTo index

    transitionEndHandler = ->
      $box.removeClass 'moving'

    calcNextIndex_ = ->
      endTime = new Date().getTime()
      timeDiff = endTime - startTime
      distanceX = endX - startX
      index = currentIndex
      if timeDiff < 300 and Math.abs(distanceX) > 30
        if distanceX > 0 then index-- else index++
      else
        currX = getTranslateX() - containerOffsetLeft
        d = Math.abs((minLeft + currX) - containerBaseX - itemWidth / 2)
        index = Math.floor(d / itemWidth)
      return Math.max(0, Math.min(index, itemLength - 1))

    moveTo = (index) ->
      $box.addClass 'moving'
      $flickBox.trigger(EventType.FG_CHANGE, [index])  if currentIndex isnt index
      currentIndex = index
      $box.css CSS_TRANSFORM, getCssTranslateValue(containerBaseX + itemWidth * currentIndex * -1)
      $navChildren.removeClass('selected').eq(currentIndex).addClass 'selected'  if useNav
      disableArrow()  if useArrows


    ###
      initialize base variable and bind events
    ###
    $container.height(boxHeight).scroll ->
      $(this).scrollLeft 0

    $box.height(boxHeight).width(boxWidth).css CSS_TRANSFORM, getCssTranslateValue(getTranslateX())

    $(window).bind (if isMobile then EventType.ORIENTATION_CHAGE else EventType.RESIZE), redefineLeftOffset
    redefineLeftOffset()

    if useNav
      $navChildren.eq(0).addClass 'selected'
      $navA.bind(EventType.START, (e) ->
        index = $navA.index(this)
        moveTo index
        false
      ).bind EventType.CLICK, ->
        false

    if useArrows
      $prev.bind EventType.START, prevTappedHandler
      $next.bind EventType.START, nextTappedHandler
      disableArrow()

    touchEvents = [ EventType.MOVE, EventType.START, EventType.END ]
    if isMobile
      box = $box[0]
      $.each touchEvents, (i, e) ->
        box.addEventListener e, touchHandler, false
      box.addEventListener EventType.TRANSITION_END, transitionEndHandler, false
    else
      $box.bind(touchEvents.join(' '), touchHandler).bind EventType.TRANSITION_END, transitionEndHandler
