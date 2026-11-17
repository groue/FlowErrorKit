struct FrobnicateError: Error {
    var title: String
    var message: String
    var isRecoverable: Bool
    
    static func random() -> Self {
        [
            FrobnicateError(
                title: "Could Not Frobnicate the Foobar",
                message: "The foobar is too strong. Try again, maybe?",
                isRecoverable: true),
            FrobnicateError(
                title: "Frobnication Forbidden",
                message: "You are not authorized.",
                isRecoverable: false),
            FrobnicateError(
                title: "Missing Frobnicator",
                message: "Can't proceed.",
                isRecoverable: false),
            FrobnicateError(
                title: "Frobnication Interrupted by the Foobar",
                message: "The foobar is playful. Try again, maybe?",
                isRecoverable: true),
            FrobnicateError(
                title: "Invalid Frobnication Certificate",
                message: "Generate a new certificate and try again.",
                isRecoverable: true),
            FrobnicateError(
                title: "Frobnication Error",
                message: "Code 2000 (unknown error)",
                isRecoverable: true),
        ].randomElement()!
    }
}
