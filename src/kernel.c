// Simple Hello World Kernel.
struct text_attr_st {
  char c;
  unsigned char attr;
};

typedef struct text_attr_st text_attr_t;

text_attr_t *TextBuffer = (text_attr_t*)0xb8000;

void KernelInit(void) {
  int i;

  const char *text = "Hello World";
  const int pos = 12 * 80 + 35;


  for(i = 0; i < 25 * 80; i++) {
    TextBuffer[i].c = ' ';
    TextBuffer[i].attr = 7;
  }

  for(i = 0; text[i]; i++) {
    TextBuffer[i + pos].c = text[i];
    TextBuffer[i + pos].attr = (i % 7) + 1 + 8;
  }

  // Stop.
  for(;;) __asm("hlt");
}

