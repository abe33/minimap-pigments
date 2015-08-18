MinimapPigments = require '../lib/minimap-pigments'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "MinimapPigments", ->
  [workspaceElement, editor, minimapPackage, minimap, pigmentsProject, colorBuffer, plugin, binding] = []

  editBuffer = (text, options={}) ->
    if options.start?
      if options.end?
        range = [options.start, options.end]
      else
        range = [options.start, options.start]

      editor.setSelectedBufferRange(range)

    editor.insertText(text)
    editor.getBuffer().emitter.emit('did-stop-changing') unless options.noEvent

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.workspace.open('sample.sass').then (textEditor) ->
        editor = textEditor

    waitsForPromise ->
      atom.packages.activatePackage('pigments').then (pkg) ->
        pigmentsProject = pkg.mainModule.getProject()

    waitsForPromise ->
      atom.packages.activatePackage('minimap').then (pkg) ->
        minimapPackage = pkg.mainModule

    waitsForPromise ->
      atom.packages.activatePackage('minimap-pigments').then (pkg) ->
        plugin = pkg.mainModule

    runs ->
      minimap = minimapPackage.minimapForEditor(editor)
      colorBuffer = pigmentsProject.colorBufferForEditor(editor)

    waitsFor ->
      binding = plugin.bindingForEditor(editor)

    runs ->
      spyOn(minimap, 'decorateMarker').andCallThrough()

  describe "with an open editor that have a minimap", ->
    beforeEach ->
      waitsForPromise -> colorBuffer.initialize()

    it "creates a binding between the two plugins", ->
      expect(binding).toBeDefined()

    it 'decorates the minimap with color markers', ->
      expect(minimap.decorateMarker).toHaveBeenCalled()

    describe 'when a color is added', ->
      beforeEach ->
        editor.moveToBottom()
        editBuffer('  border-color: yellow')

        waitsFor -> minimap.decorateMarker.callCount > 2

      it 'adds a new decoration on the minimap', ->
        expect(minimap.decorateMarker.callCount).toEqual(3)

    describe 'when a color is removed', ->
      beforeEach ->
        spyOn(minimap, 'removeAllDecorationsForMarker').andCallThrough()

        editBuffer('', start: [2,0], end: [2, Infinity])

        waitsFor -> minimap.removeAllDecorationsForMarker.callCount > 0

      it 'removes the minimap decoration', ->
        expect(minimap.removeAllDecorationsForMarker.callCount).toEqual(1)

    describe 'when the editor is destroyed', ->
      beforeEach ->
        spyOn(binding, 'destroy').andCallThrough()
        editor.destroy()

      it 'also destroy the binding model', ->
        expect(binding.destroy).toHaveBeenCalled()

        expect(plugin.bindingForEditor(editor)).toBeUndefined()

    describe 'when the plugin is deactivated', ->
      beforeEach ->
        spyOn(binding, 'destroy').andCallThrough()

        plugin.deactivatePlugin()

      it 'removes all the decorations from the minimap', ->
        expect(binding.destroy).toHaveBeenCalled()
