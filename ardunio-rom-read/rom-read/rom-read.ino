// Reads ROM using SPI read instruction (0x03 for XMC ROM chip)
// Prints the data byte at address over UART
// (Use Putty to save serial log output)

// default SPI pins used

#include <SPI.h>

#define SLAVE_CS 10
#define M 1000000
#define BAUD_RATE 115200

// opcodes
#define RDID 0x9F
#define READ 0x03

// values to confirm
#define MAN_ID 0x20
#define MEM_TYPE 0x70
#define CAP 0x17

#define CHIP_SIZE 8388608 // in bytes
// SPI mode 0
// SPI speed = 1MHz
// MSB SPI read
int SPI_speed = 1 * M;
SPISettings slave_settings(SPI_speed, MSBFIRST, SPI_MODE0);

bool RDID_read() {
  uint8_t man, mem, cap;
  bool isCorrect = false;

  SPI.beginTransaction(slave_settings);
  digitalWrite(SLAVE_CS, LOW);

  SPI.transfer(RDID);
  man = SPI.transfer(0);
  mem = SPI.transfer(0);
  cap = SPI.transfer(0);
  
  digitalWrite(SLAVE_CS, HIGH);
  SPI.endTransaction();

  isCorrect = (man == MAN_ID && mem == MEM_TYPE && cap == CAP);

  Serial.println("==RDID VERIFY START==");

  Serial.print("Correct?=");
  Serial.println(isCorrect);

  Serial.print("MAN_ID=");
  Serial.println(man, HEX);

  Serial.print("MEM_TYPE=");
  Serial.println(mem, HEX);

  Serial.print("CAP=");
  Serial.println(cap, HEX);

  Serial.println("==RDID VERIFY END==");

  return isCorrect;
}

void ROM_read() {
  
  uint8_t buffer;

  Serial.println("==ROM READ START==");

  for (uint32_t i = 0; i < CHIP_SIZE; i++) {
    SPI.beginTransaction(slave_settings);
    digitalWrite(SLAVE_CS, LOW);
    
    // (uint8_t) 0x1234 : convert a hex constant to an unsigned byte (i.e. 0x34)
    // 24 bit addr    
    uint8_t nib0 = (uint8_t) (i >> 0);
    uint8_t nib1 = (uint8_t) (i >> 8);
    uint8_t nib2 = (uint8_t) (i >> 16);

    SPI.transfer(READ);
    SPI.transfer(nib2);
    SPI.transfer(nib1);
    SPI.transfer(nib0);

    buffer = SPI.transfer(0);

    digitalWrite(SLAVE_CS, HIGH);
    SPI.endTransaction();

    Serial.println(buffer, HEX);
    
    // prob dont need this
    delayMicroseconds(5);
  }

  Serial.println("==ROM READ END==");

}

void setup() {
  // init serial at 115200 baud
  Serial.begin(BAUD_RATE);
  // chip select pin init
  pinMode(SLAVE_CS, OUTPUT);
  // init SPI
  SPI.begin();
}

void loop() {
 
  // loop until RDID is confirmed and start reading data
  // takes forever, 2+ hrs

  if (RDID_read()) {
    delay(1000);
    ROM_read();
    delay(100);
    exit(0);
  }
  delay(1000);
}
 