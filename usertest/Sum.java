class Sum {
    public static void main(String[] args) {
        int a = 5;
        boolean testAT = a == 5;
        boolean testAF = a < 5;
        int b = 3;
        boolean test1 = b < a;
        boolean test2 = b == a;
        int c = 0;
        if (unknown) {
          c = a + b;
        }
        else {
          c = a - b;
        }
        int d = c*c;
        int e = boo; // unknown variable should be treated as anything
        boolean test3 = e < 10;
    }
}
