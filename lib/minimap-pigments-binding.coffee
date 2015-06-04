{CompositeDisposable} = require 'atom'

module.exports =
class MinimapPigmentsBinding
  constructor: ({@editor, @minimap, @colorBuffer}) ->
    @displayedMarkers = []
    @subscriptions = new CompositeDisposable

    @colorBuffer.initialize().then => @updateMarkers()

    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers => @updateMarkers()

  updateMarkers: ->
    markers = @colorBuffer.findValidColorMarkers()

    console.log @displayedMarkers, markers

    for m in @displayedMarkers when m not in markers
      @minimap.removeAllDecorationsForMarker(m.marker)

    for m in markers when m.color?.isValid() and m not in @displayedMarkers
      @minimap.decorateMarker(m.marker, type: 'highlight', color: m.color.toCSS())

    @displayedMarkers = markers

  destroy: ->
    @subscriptions.dispose()
