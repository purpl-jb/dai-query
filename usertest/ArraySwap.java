// A Java version of test_cases/js/bucket_swap.js
public class ArraySwap {
    static boolean swap(int[] array, int i, int j) {
        int temp;

        if (i < 0 || i >= array.length || j < 0 || j >= array.length) {
            return false;
        }
        temp = array[i];
        array[i] = array[j];
        array[j] = temp;
        return true;
    }
    
    public static void main(String[] args) {
        int[] numberArray = {1, 8, 10};//;1, 8, 8, 8, 10, 10};
        boolean mustTrue = numberArray[1] == 8;
        
        // test cases "swap only accepts valid positions"
        boolean test1 = swap(numberArray, 0, 2);
        boolean test2 = swap(numberArray, 0, 1);
        
        // JB: the analysis is unsound :( it reports true here
        boolean mustFalse = numberArray[1] == 8;
        
        // test cases "swap accepts bad positions"
        boolean test3 = swap(numberArray, 42, 1);
    }
}
