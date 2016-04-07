assert = require('chai').assert
StickyEntity = require '../src/StickyEntity'

describe.only 'StickyEntity', ->
  before ->
    @stickyEntity = new StickyEntity()

    @design = {contents: [
      {
        _type: 'TextQuestion'
        _id: 'testId'
        sticky: true
      }
    ]}

    @stickyStorage = {
      get: (questionId) ->
        assert.equal questionId, 'testId'
        return 'data'
    }

  it 'sets a sticky value for a question that was invisible and just became visible', ->

    data = {somethingElse: 'random data'}

    previousVisibilityStructure = {'testId': false}
    newVisibilityStructure = {'testId': true}

    newData = @stickyEntity.setStickyData(@design, data, @stickyStorage, previousVisibilityStructure, newVisibilityStructure)

    expectedData = {
      testId: {value: 'data'}
      somethingElse: 'random data'
    }

    assert data != newData
    assert.deepEqual expectedData, newData

  it "sets a sticky value for a question that just became visible because previousVisibilityStructure is empty", ->

    data = {somethingElse: 'random data'}

    previousVisibilityStructure = {}
    newVisibilityStructure = {'testId': true}

    newData = @stickyEntity.setStickyData(@design, data, @stickyStorage, previousVisibilityStructure, newVisibilityStructure)

    expectedData = {
      testId: {value: 'data'}
      somethingElse: 'random data'
    }

    assert data != newData
    assert.deepEqual expectedData, newData

  it "doesn't sets a sticky value for a question that was already set", ->
    data = {somethingElse: 'random data', testId: {value: 'a'}}
    previousVisibilityStructure = {}
    newVisibilityStructure = {'testId': true}

    newData = @stickyEntity.setStickyData(@design, data, @stickyStorage, previousVisibilityStructure, newVisibilityStructure)

    assert.deepEqual data, newData

  it "doesn't sets a sticky value for a question that was already visible", ->
    data = {somethingElse: 'random data'}
    previousVisibilityStructure = {'testId': true}
    newVisibilityStructure = {'testId': true}

    newData = @stickyEntity.setStickyData(@design, data, @stickyStorage, previousVisibilityStructure, newVisibilityStructure)

    assert.deepEqual data, newData

  it "doesn't sets a sticky value for a question that stays invisible", ->
    stickyEntity = new StickyEntity()

    design = {contents: [
      {
        _type: 'TextQuestion'
        _id: 'testId'
        sticky: true
      }
    ]}
    data = {somethingElse: 'random data'}
    stickyStorage = {
      get: () ->
        'data'
    }
    previousVisibilityStructure = {'testId': false}
    newVisibilityStructure = {'testId': false}

    newData = stickyEntity.setStickyData(design, data, stickyStorage, previousVisibilityStructure, newVisibilityStructure)

    assert.deepEqual data, newData
