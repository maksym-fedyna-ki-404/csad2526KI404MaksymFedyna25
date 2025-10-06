# csad2526KI404MaksymFedyna25

## Running Unit Tests

To build and run the unit tests using CMake and Google Test:

1. **Configure the project and generate build files:**
   ```sh
   cmake -S . -B build
   ```
2. **Build the test executable:**
   ```sh
   cmake --build build
   ```
3. **Run the tests:**
   ```sh
   ctest --test-dir build
   ```
   Or run the test executable directly:
   ```sh
   ./build/unit_tests
   ```

Make sure CMake is installed and available in your PATH. Google Test will be automatically downloaded and built as part of the process.
