// A Java version of test_cases/js/bucket_contains.js
public class ArrayContains {
    static int indexOf(int[] array, int item) {
        for (int i = 0; i < array.length; i++) {
            // JB: for some reason, equality doesn't work
            if (array[i] == item) {
                return i;
            }
        }
        /*int length = array.length;
        int i = 0;
        while (i < length) {
            if (array[i] == item) {
                return i;
            }
            i += 1;
        }*/
        return -1;
    }
    
    static boolean contains(int[] array, int item) {
        int tmp = indexOf(array, item);
        return tmp >= 0;
    }
    
    static int get1(int[] array) {
        return array[1];
    }

    public static void main(String[] args) {
        int[] numberArray = {1, 8, 10};//;1, 8, 8, 8, 10, 10};
        int[] emptyArray = { };
        
        int v42 = 42;
        boolean flag = numberArray[0] == v42;
        
        int getTest1 = get1(numberArray);
        int indTest1 = indexOf(numberArray, 1);
        int indTest2 = indexOf(numberArray, 8);
        
        //test cases "contains returns true for existing numbers"
        boolean test1 = contains(numberArray, 1);
        //boolean test2 = contains(numberArray, 8);
        //boolean test3 = contains(numberArray, 10);

        //test cases "contains returns false for non existing numbers"
        //boolean test4 = contains(numberArray, 11);
        boolean test5 = contains(emptyArray, 8);
    }
}
