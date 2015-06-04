{CompositeDisposable} = require 'event-kit'
MinimapPigmentsBinding = require './minimap-pigments-binding'

module.exports =
  active: false
  bindings: {}

  isActive: -> @active

  activate: (state) ->
    @subscriptions = new CompositeDisposable

  consumeMinimapServiceV1: (@minimap) ->
    @minimap.registerPlugin 'pigments', this

  consumePigmentsServiceV1: (@pigments) ->
    @initialize() if @minimap? and @active

  deactivate: ->
    @minimap.unregisterPlugin 'pigments'
    @minimap = null

  activatePlugin: ->
    return if @active

    @active = true

    @initialize() if @pigments?

  initialize: ->
    @editorsSubscription = @pigments.observeColorBuffers (colorBuffer) =>
      editor = colorBuffer.editor
      minimap = @minimap.minimapForEditor(editor)

      binding = new MinimapPigmentsBinding({editor, minimap, colorBuffer})
      @bindings[editor.id] = binding

      subscription = editor.onDidDestroy =>
        binding.destroy()
        delete @bindings[editor.id]
        subscription.dispose()

  bindingForEditor: (editor) ->
    return @bindings[editor.id] if @bindings[editor.id]?

  deactivatePlugin: ->
    return unless @active

    for id,binding of @bindings
      binding.destroy()
      delete @bindings[id]

    @active = false
    @editorsSubscription?.dispose()
    @subscriptions.dispose()
