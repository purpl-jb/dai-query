class Ifs {
    public static void main(String[] args) {
				int c1 = 42;
				int sum = 0;
				// for some reason, c1 == 42 is not 
				// abstractly evaluated to true
				if (c1 > 0) {
					sum = 10;
				} else {
					sum = -10;
				}
				sum += 5;
    }
}
