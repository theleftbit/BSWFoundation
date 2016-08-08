
import BSWFoundation
import Deferred

/*:
 - important: If you prefer, there is also a presentation for this section, found [here](https://speakerdeck.com/piercifani/why-swift)
 
 # Result<T>
 
 Things **can** go wrong in software. And if Murphy's law has taught us anything, is that things **will** go wrong.
 
 That is why it's important to express our code in terms of operations that could fail at compile time.
 
 Let's see what's wrong with this function, which calculates the power of two of an element the user introduced in a `UITextField`, which is, off course, a `String`:
 */
func calculatePowerOf2(value: String) -> Float {
    guard let floatValue = Float(value) else { return 0 }
    return pow(floatValue, 2)
}

let invalidCharacter = "h"
let validCharacter = "2"

let invalidValue: Float = calculatePowerOf2(invalidCharacter)
let validValue: Float =  calculatePowerOf2(validCharacter)

/*:
 Notice that if the String couldn't be cast to a number, we are returning 0, because we have no way of notifying the caller that the operation couldn't be completed in a more expressive way.
 
 We could, off course, take a hint from Objective-C, which modeled this operations passing an NSError's pointer to the function, and setting that to an appropiate error when available, like this:

 ```
 NSError *err = nil;
 CGFloat result = [NMArithmetic divide:2.5 by:3.0 error:&err];
 if (err) {
    NSLog(@"%@", err)
 } else {
    [NMArithmetic doSomethingWithResult:result]
 }
```
 
 However, this introduces new problems:
 
 1. On the calling site, we have to **remember** to check for the `NSError`, which makes it too easy to just pass `nil` and keep coding.
 2. On the function site, we have to make sure that every code path takes into account the error, otherwise we might be "leaking" the error, and producing an unknown state.
 
 More on this [here](http://www.sunsetlakesoftware.com/2014/12/02/why-were-rewriting-our-robotics-software-swift)

 Compare the previous version to this one, written using `Result<T>`:
 */

func calculatePowerOf2(value: String) -> Result<Float> {
    
    enum PowerError: ErrorType {
        case couldNotCast
    }
    
    guard let floatValue = Float(value) else { return .Failure(PowerError.couldNotCast) }
    return Result(pow(floatValue, 2))
}

let failedResult: Result<Float> = calculatePowerOf2(invalidCharacter)
let succesfulResult: Result<Float> = calculatePowerOf2(validCharacter)

/*:
 Much better! Now on the calling site we have to explicitly handle the error case, which leads to safer code. 
 
 Also, on the function site we now have to explicitly return an error when something fails. On the example above, we created an `enum` to handle all the possible errors that could be thrown from that function. We could also use enum's associated values to attach more information of the error if necessary.
 
 But, this doesn't stop here. `Result` is a [monad](https://en.wikipedia.org/wiki/Monad_(functional_programming)), which means that we can use `map` to create more complex operations:
 */

func multiplyByTwo(value: Float) -> Float {
    return value * 2
}

let compoundOperation = calculatePowerOf2(validCharacter)
                        .map(multiplyByTwo)

switch compoundOperation {
case .Success(let value):
    print("The value is \(value)")
case .Failure(let error):
    print("There was an error: \(error)")
}

/*:
 This allows us to decompose complex problems into functions that are:
 
 1. Small.
 2. Easy to reason about.
 3. Easy to test.
 
 Then, using `map` and `flatMap` we "stich" these functions togheter to make sure that we have a valid solution for the complex problem. Like this:
 ```    
 public func fetchLocationAndUsers() -> Result<[User]> {
        return fetchCurrentLocation()
                .map(buildSearchFilter)
                .flatMap(fetchUsers)
 }
```
 */


