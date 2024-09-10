
import Testing
import BSWFoundation

actor CollectionTests {

    private let sample = [1,2,3,4,5,6,7,8,9]

    @Test
    func find() {
        #expect(sample.find(predicate: {$0 == 1}) != nil)
        #expect(sample.find(predicate: {$0 == 42}) == nil)
    }

    @Test
    func safe() {
        #expect(sample[safe: 0] != nil)
        #expect(sample[safe: 42] == nil)
    }

    @Test
    func shuffle() {
        //These tests are testing for randomness, let's try up to 10 times if any of them fails
        for _ in 0...10 {
            let testShuffledArrayChanges = sample.shuffled() != sample
            let testShuffledEmptyArrayDoesntChange = [0].shuffled() == [0]
            let testRandomElement = sample.randomElement != 0
            if testShuffledArrayChanges && testShuffledEmptyArrayDoesntChange && testRandomElement {
                return
            }
        }
        Issue.record("Shuffling tests failed")
    }

    @Test
    func moveItem() {
        var mutableSample = sample
        mutableSample.moveItem(fromIndex: 0, toIndex: 1)
        #expect(mutableSample[0] == 2)
        #expect(mutableSample[1] == 1)
    }

    @Test
    func dictionaryInitWithTuples() {
        let tuples = [(0, 1), (1, 1), (2, 1), (3, 1)]
        let dict = Dictionary(elements: tuples)
        #expect(dict[0] != nil)
        #expect(dict[1] != nil)
        #expect(dict[2] != nil)
        #expect(dict[3] != nil)
        #expect(dict[42] == nil)
    }
    
    @Test
    func selectableArray() {
        let values = [0,1,2,3]
        var array = SelectableArray<Int>(options: values)
        array.select(atIndex: 2)
        #expect(array.selectedElement == 2)
        array.enumerated().forEach { (offset, _) in
            #expect(array[offset] == values[offset])
        }
        array.appendOption(4, andSelectIt: true)
        #expect(array.selectedElement == 4)
    }
    
    @Test
    func selectableArrayImmutable() {
        let values = [0,1,2,3]
        let array = SelectableArray<Int>(options: values)
        let newArray = array.appendingOption(4, andSelectIt: true)
        #expect(newArray.selectedElement == 4)
    }

    @Test
    func selectableArrayEquatable() {
        let array1 = SelectableArray<Int>(options: [0,1,2,3])
        let array2 = SelectableArray<Int>(options: [4,1,2,3])
        #expect(array1 != array2)
    }
    
    @Test
    func selectableArrayEquatable2() {
        var array1 = SelectableArray<Int>(options: [0,1,2,3])
        array1.select(atIndex: 0)
        let array2 = SelectableArray<Int>(options: [0,1,2,3])
        #expect(array1 != array2)
    }
    
    @Test
    func removeSelectionSelectableArray() {
        var array1 = SelectableArray<Int>(options: [0,1,2,3])
        array1.select(atIndex: 0)
        array1.removeSelection()
        #expect(array1.selectedElement == nil)
    }
}
