/// Construct a static get function for any zig file.
pub fn Type(comptime T : type) type {
    return struct {
        // Const structs function like static in C++
        const static = struct {
            var instance = T {};
        };
        // We use this to create a pointer to the type.
        pub fn get() *T {
            return &static.instance;
        }
    };
}