#define REQUIRED_ARGC 2
#define MAX_SIZE 1000
#define FIELD_SIZE 6

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <mkl_types.h>

typedef struct occ {
  char name[15];
  int occurence;
  double frames;
} Occupation;

// functions declaration
int str_split(char *, char *[]);
void print_occupation( Occupation );

int main(int argc, char* argv[])
{
  // check for required arguments
  assert(argc >= REQUIRED_ARGC);

  // open statsfile
  FILE *statsfile;
  statsfile = fopen(argv[1], "r");
  if (statsfile == NULL)
    exit(EXIT_FAILURE);

  char *line = NULL; // dynamically allocated
  size_t len = 0;
  ssize_t read;
  char *token[MAX_SIZE];

  printf("%-15s , %s\n", "Triphone", "# of frames");
  while ((read = getline(&line, &len, statsfile)) != -1) {
    int token_size = str_split(line, token);
    if (token_size == FIELD_SIZE) {
      Occupation o;
      strcpy(o.name, token[1]);
      o.occurence = atoi(token[2]);
      o.frames = atof(token[3]) + atof(token[4]) + atof(token[5]);

      print_occupation(o);
    }
  }
  fclose(statsfile);

  // release memory
  if (line) {
    free(line);
  }

  // exit with status 0
  exit(EXIT_SUCCESS);
}

// print_occupation
void print_occupation(Occupation o) {
  printf("%-15s = %-2.2f\n", o.name, o.frames/o.occurence);
}

// next_token
char* next_token(char *p) {
  while (isspace(*p)) {
    ++p;
  }
  return *p ? p : NULL;
}

// next_space
char* next_space(char *p) {
  while (!isspace(*p) && *p) {
    ++p;
  }
  return *p ? p : NULL;
}

// str_split - split string by space
int str_split(char *p, char *token[])
{
  int n = 0;
  while ((p = next_token(p)) != NULL) {
    token[n++] = p;
    if ((p = next_space(p)) == NULL) {
      break;
    }
    *p++ = '\0';
  }
  return n;
}
