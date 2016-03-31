assert = require('chai').assert

TestComponent = require('react-library/lib/TestComponent')
ReactTestUtils = require('react-addons-test-utils')

RadioAnswerComponent = require '../../src/answers/RadioAnswerComponent'

React = require 'react'
ReactDOM = require 'react-dom'
R = React.createElement
H = React.DOM

# nodeType is 1, not 3 so TestComponent.findComponentByText wasn't working
findComponentByText = (component, pattern) ->
  return ReactTestUtils.findAllInRenderedTree(component, (c) ->
    # Only match DOM components with a child node that is matching string
    if ReactTestUtils.isDOMComponent(c)
      _.any(c.childNodes, (node) ->
        (node.nodeType == 3 or node.nodeType == 1) and node.textContent.match(pattern))
  )[0]

# nodeType is 1, not 3 so TestComponent.findComponentByText wasn't working
findComponentById = (component, id) ->
  return ReactTestUtils.findAllInRenderedTree(component, (c) ->
    c.id == id
  )[0]

describe 'RadioAnswerComponent', ->
  before ->
    @toDestroy = []

    @render = (options = {}) =>
      options = _.extend {
        answer: {}
        choices: [
          { id: "a", label: { _base: "en", en: "AA" }, hint: { _base: "en", en: "a-hint" } }
          { id: "b", label: { _base: "en", en: "BB" } }
          { id: "c", label: { _base: "en", en: "CC" }, specify: true }
        ],
        onAnswerChange: () ->
          null
      }, options

      elem = R(RadioAnswerComponent, options)
      comp = new TestComponent(elem)
      @toDestroy.push(comp)
      return comp

  afterEach ->
    for comp in @toDestroy
      comp.destroy()
    @toDestroy = []

  it "displays choices", ->
    testComponent = @render()

    choiceA = findComponentByText(testComponent.getComponent(), /AA/)
    assert choiceA?, 'Not showing choice AA'

    choiceB = findComponentByText(testComponent.getComponent(), /BB/)
    assert choiceB?, 'Not showing choice BB'

    choiceC = findComponentByText(testComponent.getComponent(), /CC/)
    assert choiceC?, 'Not showing choice CC'

  it "displays choice hints", ->
    testComponent = @render()

    hintA = findComponentByText(testComponent.getComponent(), /a-hint/)
    assert hintA?, 'Not showing hint'

  it "records selected choice", (done) ->
    testComponent = @render({
      onAnswerChange: (answer) ->
        assert.equal answer.value, 'a'
        done()
    })

    choiceA = findComponentById(testComponent.getComponent(), 'a')

    assert choiceA?, 'could not find choice A'
    TestComponent.click(choiceA)

  it "allows unselecting choice by clicking twice", (done) ->
    testComponent = @render({
      answer: {value: 'b'}
      onAnswerChange: (answer) ->
        assert.deepEqual answer.value, null
        done()
    })

    choiceB = findComponentById(testComponent.getComponent(), 'b')

    assert choiceB?, 'could not find choice B'
    TestComponent.click(choiceB)

  it "displays specify box", ->
    testComponent = @render {value: 'c'}

    specifyInput = ReactTestUtils.findRenderedDOMComponentWithClass.bind(this, testComponent.getComponent(), 'specify-input')

    assert specifyInput?, 'could not find specify input'

  it "it doesn't displays specify box when a choice without specify is selected", ->
    testComponent = @render {value: 'a'}

    assert.throws(ReactTestUtils.findRenderedDOMComponentWithClass.bind(this, testComponent.getComponent(), 'specify-input'), 'Did not find exactly one match (found: 0) for class:specify-input')

  it "records specify value", (done) ->
    testComponent = @render {
      onAnswerChange: (answer) ->
        assert.deepEqual answer.specify, {'c': 'specify'}
        done()
      answer: {value: 'c'}
    }

    specifyInput = ReactTestUtils.findRenderedDOMComponentWithClass(testComponent.getComponent(), 'specify-input')
    TestComponent.changeValue(specifyInput, 'specify')

  it "removes specify value on other selection", (done) ->
    testComponent = @render {
      onAnswerChange: (answer) ->
        assert.equal answer.specify, null
        done()
      answer: {value: 'c'}
      specify: {c: 'specify'}
    }

    choiceC = findComponentById(testComponent.getComponent(), 'c')
    assert choiceC?, 'could not find choice C'
    TestComponent.click(choiceC)
