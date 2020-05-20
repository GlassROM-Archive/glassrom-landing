#include <stdio.h>
// clang-format puts this above stdio.h
// this is an error. stdio.h should be included before readline
#include <readline/history.h>
#include <readline/readline.h>
#include <stdlib.h>
#include <string.h>
#include <uuid/uuid.h>

char *getuuid(char *uuid);
int main(int argc, char **argv) {
  // just ignore the command line arguments
  (void)argc;
  (void)argv;
  // this variable holds our timestamp
  unsigned long a = (unsigned long)time(NULL);
  // name stores the name of the full zip. name1 stores the name of the
  // incremental zip. Link stores a base URI from where both files can be
  // acccessed. The code will always assume both files are in the same directory
  static char *name = NULL, *name1 = NULL, *link = NULL, *temp = NULL;
  // a random number
  char update_id[37];
  // base download link where both full and incremental zip are stored
  // size is the size of the full OTA. size1 is the size of the incremental OTA
  unsigned long long size, size1;
  // the variable we use to store the uuid in the binary representation
  uuid_t temp_update_id;
  // this is used to safely accept user input for the size variables
  // spaces are needed for fornatting and since this is needed often keep a
  // const variable for it
  const char five_spaces[] = "     ";

  // generate uuid
  uuid_generate_random(temp_update_id);
  // convert the generated uuid from binary to text (lowercase)
  uuid_unparse_lower(temp_update_id, update_id);
  // open the updates file for reading
  FILE *updates = fopen("updates.json", "a");

  // get information about full OTA
  name = readline("Enter file name for full OTA. must have no spaces ");
  // strip trailing newline
  name[strcspn(name, "\n")] = 0;

  temp = readline(
      "Enter file size in bytes. use wc -c <update.zip to find this. values "
      "above 100 GB are not allowed ");
  size = (unsigned long long)strtoll(temp, NULL, 10);

  name1 = readline(
      "Enter file name for incremental OTA. must have no spaces, 199 chars "
      "max ");
  name1[strcspn(name1, "\n")] = 0;

  // get incremental OTA details
  temp = readline(
      "Enter file size in bytes. use wc -c <update.zip to find this. values "
      "above 100 GB are not allowed ");
  size1 = (unsigned long long)strtoll(temp, NULL, 10);

  link = readline(
      "Enter base download link without a trailing slash. The filename will "
      "be appended to this ");
  link[strcspn(link, "\n")] = 0;

  // if size is 0 then user did not enter a valid number and if size1
  // (incremental size) > size (full size) something is wrong
  if (size == 0 || size1 == 0 || size1 > size) {
    fclose(updates);
    if (temp)
      printf("invalid size. exiting");
    else
      printf("Out of memory error");
    goto free;
  }

  if (!(name && name1 && link && temp)) {
    printf("FAILED: out of memory?");
    goto free;
  }

  // write full OTA information to file
  fprintf(
      updates,
      "{\n  \"response\": [\n    {\n%s\"datetime\": %lu,\n%s\"filename\": "
      "\"%s\",\n%s\"id\": \"%s\",\n%s\"romtype\": \"unofficial\",\n%s\"size\": "
      "%lld,\n%s\"url\": \"%s/%s\",\n%s\"version\": \"17.1\"\n    },\n",
      five_spaces, a, five_spaces, name, five_spaces, getuuid(update_id),
      five_spaces, five_spaces, size, five_spaces, link, name, five_spaces);

  // change the UUID for the incremental OTA
  uuid_generate_random(temp_update_id);
  uuid_unparse_lower(temp_update_id, update_id);

  // write incremental OTA details
  fprintf(
      updates,
      "    {\n%s\"datetime\": %lu,\n%s\"filename\": "
      "\"%s\",\n%s\"id\": \"%s\",\n%s\"romtype\": \"unofficial\",\n%s\"size\": "
      "%lld,\n%s\"url\": \"%s/%s\",\n%s\"version\": \"17.1\"\n    }\n  ]\n}\n",
      five_spaces, a, five_spaces, name1, five_spaces, getuuid(update_id),
      five_spaces, five_spaces, size1, five_spaces, link, name1, five_spaces);
  // close the file
  fclose(updates);
  updates = NULL;
  printf("check updates.json\n");
free:
  updates = NULL;
  if (name)
    free(name);
  if (name1)
    free(name1);
  if (link)
    free(link);
  if (temp)
    free(temp);
  name = name1 = link = temp = NULL;
  rl_clear_history();
  clear_history();
}

// we need this to remove dashes from the uuid
char *getuuid(char *uuid) {
  char *a;
  while (strstr(uuid, "-")) {
    a = strstr(uuid, "-");
    // randomly return a number from 0-8. why not 9? well i was bored, that's
    // why
    *a = 48 + (rand() % 9);
  }
  return uuid;
}
