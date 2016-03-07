{CompositeDisposable} = require 'atom'

module.exports =
class MinimapPigmentsBinding
  constructor: ({@editor, @minimap, @colorBuffer}) ->
    @displayedMarkers = []
    @decorationsByMarkerId = {}
    @subscriptionsByMarkerId = {}

    @subscriptions = new CompositeDisposable

    @colorBuffer.initialize().then => @updateMarkers()

    @subscriptions.add @colorBuffer.editor.displayBuffer.onDidTokenize =>
      @updateMarkers()
    @subscriptions.add @colorBuffer.onDidUpdateColorMarkers =>
      @updateMarkers()

    @decorations = []

  updateMarkers: ->
    markers = @colorBuffer.findValidColorMarkers()

    for m in @displayedMarkers when m not in markers
      @decorationsByMarkerId[m.id]?.destroy()

    for m in markers when m.color?.isValid() and m not in @displayedMarkers
      decoration = @minimap.decorateMarker(m.marker, type: 'highlight', color: m.color.toCSS(), plugin: 'pigments')

      @decorationsByMarkerId[m.id] = decoration
      @subscriptionsByMarkerId[m.id] = decoration.onDidDestroy =>
        @subscriptionsByMarkerId[m.id]?.dispose()
        delete @subscriptionsByMarkerId[m.id]
        delete @decorationsByMarkerId[m.id]

    @displayedMarkers = markers

  destroy: ->
    @destroyDecorations()
    @subscriptions.dispose()

  destroyDecorations: ->
    sub?.dispose() for id,sub of @subscriptionsByMarkerId
    decoration?.destroy() for id,decoration of @decorationsByMarkerId

    @decorationsByMarkerId = {}
    @subscriptionsByMarkerId = {}
