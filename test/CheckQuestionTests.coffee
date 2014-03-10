$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$ = $
assert = require('chai').assert
FormCompiler = require '../src/FormCompiler'
commonQuestionTests = require './commonQuestionTests'

describe "CheckQuestion", ->
  beforeEach ->
    @model = new Backbone.Model()
    @compiler = new FormCompiler(model: @model, locale: "es")
    @q = {
      _id: "q1234"
      _type: "CheckQuestion"
      text: { _base: "en", en: "English", es: "Spanish" }
      label: { _base: "en", en: "label", es: "labelo" }
      required: true
    }
    @qview = @compiler.compileQuestion(@q).render()

  # Run common tests
  commonQuestionTests.call(this)

  it "displays label", ->
    assert.match @qview.el.outerHTML, /labelo/

  it "records check", ->
    @qview.$el.find(".touch-checkbox:contains('labelo')").trigger("click")
    assert.equal @model.get('q1234').value, true

  it "records uncheck", ->
    @qview.$el.find(".touch-checkbox:contains('labelo')").trigger("click")
    assert.equal @model.get('q1234').value, true

  it "checked is required ok", ->
    assert @qview.validate()
    @qview.$el.find(".touch-checkbox:contains('labelo')").trigger("click")
    assert not @qview.validate()