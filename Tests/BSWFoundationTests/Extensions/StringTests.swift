
import Testing
import BSWFoundation

actor StringTests {

    @Test
    func SHA256() {
        let value = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
        let signedValue = value.hmac(algorithm: .SHA256, key: "044a7bc2")
        #expect(signedValue == "f92828d6b9b252f5944835a9e52d1d4ca81ff86abc4a20ffccb618da77cc5b9f")
    }

    @Test
    func capitalize() {
        #expect("hola".capitalizeFirst == "Hola")
    }

}
