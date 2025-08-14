#include "kernel.h"
#include <stdint.h>
#include <stddef.h>

int terminal_col = 0;
int terminal_row = 0;

uint16_t* video_mem = 0; 

uint16_t make_char_hexcode(char displayChar, char color){
  return (color << 8) | displayChar; // x86 -> little endian so we have to invert the bytes
                                     // if we want the color cyan (0x03) and the char A (0x41)
                                     // in normal hex would be 0x4103 but we have to invert to be 0x0341  
}

void terminal_displaychar(int x, int y, char c, char color){
  video_mem[(y * VGA_WIDTH) + x] = make_char_hexcode(c, color);
}

void terminal_writechar(char c, char color){
  terminal_displaychar(terminal_col, terminal_row, c, color);
  terminal_col++;
  if(terminal_col >= VGA_WIDTH){
    terminal_col = 0;
    terminal_row++;
  }
}

void clear_terminal(){
  video_mem = (uint16_t*)(0xB8000);

  terminal_col = 0;
  terminal_row = 0;

  for(int y = 0; y < VGA_HEIGHT; y++){
    for(int x = 0; x < VGA_WIDTH; x++){
      terminal_displaychar(x, y, ' ', 0);      
    }
  }
}

size_t strlen(const char* s){
  size_t len = 0;
  while (s[len] != 0) {
    len++;
  }
  return len;
}

void print(const char* string){
  size_t len = strlen(string);
  for (int i = 0; i < len; i++) { 
    terminal_writechar(string[i], 15);
  }
}

void kernel_main(){
  clear_terminal();
  print("Hello World!");
}
