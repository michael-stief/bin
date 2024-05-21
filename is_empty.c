#include <dirent.h>
#include <unistd.h>

int main(int argc, char** argv) {
  int n = 0;
  struct dirent *d;
  DIR *dir = opendir(argv[1]);
  if (dir == NULL)
    return 1;
  while ((d = readdir(dir)) != NULL) {
    if (++n > 2)
      break;
  }
  closedir(dir);
  if (n <= 2)
    return 0;
  else
    return 2;
}
