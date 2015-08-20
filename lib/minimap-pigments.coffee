{CompositeDisposable} = require 'event-kit'
MinimapPigmentsBinding = require './minimap-pigments-binding'

module.exports =
  active: false

  isActive: -> @active

  activate: (state) ->
    @bindingsById = {}
    @subscriptionsById = {}
    @subscriptions = new CompositeDisposable

  consumeMinimapServiceV1: (@minimap) ->
    @minimap.registerPlugin 'pigments', this

  consumePigmentsServiceV1: (@pigments) ->
    @subscriptions.add @pigments.getProject().onDidDestroy => @pigments = null

    @initialize() if @minimap? and @active

  deactivate: ->
    @subscriptions.dispose()
    @editorsSubscription.dispose()
    @minimap.unregisterPlugin 'pigments'
    @minimap = null
    @pigments = null

  activatePlugin: ->
    return if @active

    @active = true

    @initialize() if @pigments?

  initialize: ->
    @editorsSubscription = @pigments.observeColorBuffers (colorBuffer) =>
      editor = colorBuffer.editor
      minimap = @minimap.minimapForEditor(editor)

      binding = new MinimapPigmentsBinding({editor, minimap, colorBuffer})
      @bindingsById[editor.id] = binding

      @subscriptionsById[editor.id] = editor.onDidDestroy =>
        @subscriptionsById[editor.id]?.dispose()
        binding.destroy()
        delete @subscriptionsById[editor.id]
        delete @bindingsById[editor.id]

  bindingForEditor: (editor) ->
    return @bindingsById[editor.id] if @bindingsById[editor.id]?

  deactivatePlugin: ->
    return unless @active

    binding.destroy() for id,binding of @bindingsById

    @active = false
    @editorsSubscription?.dispose()
