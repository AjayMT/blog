
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main()
{
  srand(time(NULL));
  int count = 0;
  for (int i = 0; i < 10000000; ++i)
  {
    int n = rand();
    if (n % 2 == 0) ++count;
  }
  printf("%d\n", count);
  return 0;
}
