class SumCallInLoop {
    /*static int sum(int x, int y){
      return x+y;
    }

    static boolean swap(int[] array, int i, int j) {
        int temp;
        if (i < 0 || i >= array.length || j < 0 || j >= array.length) {
            return false;
        }
        temp = array[i];
        array[i] = array[j];
        array[j] = temp;
        return true;
    }*/
    
    static int arrSum(int[] array) {
        int s = 0;
        for (int k = 0; k < array.length; k++) {
            s += array[k];
        }
        return s;
    }
    
    /*static int arrAbsSum(int[] array) {
        int s = 0;
        for (int k = 0; k < array.length; k++) {
            if (array[k] < 0) {
                s -= array[k];
            } else {
                s += array[k];
            }
        }
        return s;
    }*/

    public static void main(String[] args) {
        /*int v42 = sum(40, 2);
        
        int s = 0;
        int a = 5;        
        boolean testA = a < 5;
        boolean testSA = s < a;
        
        for (int i = 0; i < a; i++) {
          int v = sum(a, i);
          s += v;
        }
        boolean test1 = s >= a;*/
        
        int[] numberArray = {1, 8, -10};
        int[] emptyArray = { };
        
        int s = 0;
        for (int k = 0; k < numberArray.length; k++) {
            s += numberArray[k];
        }
        
        int anySum = arrSum(numberArray);
        int posSum = arrAbsSum(numberArray);
        
        /*boolean mustTrue = numberArray[1] == 8;
        boolean test2 = swap(numberArray, 0, 1);
        boolean mustFalse = numberArray[1] == 8;
        boolean test3 = swap(numberArray, 0, 42);*/
        
        int emptySum = arrSum(emptyArray);
    }
}
