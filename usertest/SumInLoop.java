class SumInLoop {
    /*static int sum(int x, int y){
      return x+y;
    }*/

    public static void main(String[] args) {
        int s = 0;
        int a = 5;
        boolean testA = a < 5;
        /*for (int i=0; i < 1; i++) {
          int v = s + i; //sum(s, i);
          s += v;
        }*/
        boolean test1 = s < a;
        for (int i = 0; i < 5; ++i) {
            s += a;
            a += 1;
        }
        boolean test2 = s < a;
        
        s = a;
        int b = 7;
        for (int i = 0; i < 10; ++i) {
            s += i;
            a += i;
        }
        boolean test3 = s == a;
        boolean test4 = s == 0;
    }
}
