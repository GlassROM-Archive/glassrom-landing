#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uuid/uuid.h>

char *getuuid(char *uuid);
int main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  unsigned long a = (unsigned long)time(NULL);
  static char name[200], name1[200];
  char update_id[37];
  char link[500];
  unsigned long long size, size1;
  uuid_t temp_update_id;
  char temp[12];
  const char five_spaces[] = "     ";
  uuid_generate_random(temp_update_id);
  uuid_unparse_lower(temp_update_id, update_id);
  FILE *updates = fopen("updates.json", "a");

  printf("Enter file name for full OTA. must have no spaces, 199 chars max ");
  (void)fgets(name, 200, stdin);
  name[strcspn(name, "\n")] = 0;

  printf("Enter file size in bytes. use wc -c <update.zip to find this. values "
         "above 100 GB are not allowed ");
  (void)fgets(temp, 12, stdin);
  size = (unsigned long long)strtoll(temp, NULL, 10);

  printf("Enter file name for incremental OTA. must have no spaces, 199 chars "
         "max ");
  (void)fgets(name1, 200, stdin);
  name1[strcspn(name1, "\n")] = 0;

  printf("Enter file size in bytes. use wc -c <update.zip to find this. values "
         "above 100 GB are not allowed ");
  (void)fgets(temp, 12, stdin);
  size1 = (unsigned long long)strtoll(temp, NULL, 10);

  printf("Enter base download link without a trailing slash. The filename will "
         "be appended to this ");
  (void)fgets(link, 500, stdin);
  link[strcspn(link, "\n")] = 0;

  if (size == 0 || size1 == 0)
    return printf("invalid size. exiting");

  fprintf(
      updates,
      "{\n  \"response\": [\n    {\n%s\"datetime\": %lu,\n%s\"filename\": "
      "\"%s\",\n%s\"id\": \"%s\",\n%s\"romtype\": \"nightly\",\n%s\"size\": "
      "%lld,\n%s\"url\": \"%s/%s\",\n%s\"version\": \"17.1\"\n    }\n  ]\n}\n",
      five_spaces, a, five_spaces, name, five_spaces, getuuid(update_id),
      five_spaces, five_spaces, size, five_spaces, link, name, five_spaces);

  uuid_generate_random(temp_update_id);
  uuid_unparse_lower(temp_update_id, update_id);

  fclose(updates);
  updates = fopen("updates_inc.json", "a");

  fprintf(
      updates,
      "{\n  \"response\": [\n    {\n%s\"datetime\": %lu,\n%s\"filename\": "
      "\"%s\",\n%s\"id\": \"%s\",\n%s\"romtype\": \"nightly\",\n%s\"size\": "
      "%lld,\n%s\"url\": \"%s/%s\",\n%s\"version\": \"17.1\"\n    }\n  ]\n}\n",
      five_spaces, a, five_spaces, name, five_spaces, getuuid(update_id),
      five_spaces, five_spaces, size1, five_spaces, link, name1, five_spaces);
  fclose(updates);
  printf("files are written to updates.json and updates_inc.json\n");
}

char *getuuid(char *uuid) {
  char *a;
  while (strstr(uuid, "-")) {
    a = strstr(uuid, "-");
    *a = 48 + (rand() % 9);
  }
  return uuid;
}
