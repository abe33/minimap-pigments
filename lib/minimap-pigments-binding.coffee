{CompositeDisposable} = require 'atom'

module.exports =
class MinimapPigmentsBinding
  constructor: ({@editor, @minimap, @colorBuffer}) ->
    @displayedMarkers = []
    @subscriptions = new CompositeDisposable

    @colorBuffer.initialize().then => @updateMarkers()

    @subscriptions.add @colorBuffer.editor.displayBuffer.onDidTokenize =>
      @updateMarkers()
    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers =>
      @updateMarkers()

    @decorations = []

  updateMarkers: ->
    markers = @colorBuffer.findValidColorMarkers()
    @decorations = []

    for m in @displayedMarkers when m not in markers
      @minimap.removeAllDecorationsForMarker(m.marker)

    for m in markers when m.color?.isValid() and m not in @displayedMarkers
      @decorations.push @minimap.decorateMarker(m.marker, type: 'highlight', color: m.color.toCSS())

    @displayedMarkers = markers

  destroy: ->
    @subscriptions.dispose()
    decoration.destroy() for decoration in @decorations
