#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <cstring>
#include <bitset>

using namespace std;

struct Data {
    int position;
    int type;
    int line;
};

void readData(const string& filename, int& bpm, vector<Data>& data) {
    ifstream infile(filename);
    if (!infile.is_open()) {
        cerr << "Failed to open the file: " << filename << endl;
        return;
    }

    string line;
    getline(infile, line);
    sscanf(line.c_str(), "bpm=%d", &bpm);

    while (getline(infile, line)) {
        int pos, type = 0, line_num;
        char type_str[20];
        sscanf(line.c_str(), "(%d,%[^,],%d)", &pos, type_str, &line_num);

        if (strcmp(type_str, "tap") == 0) {
            type = 1;
        } else if (strcmp(type_str, "hold_start") == 0) {
            type = 2;
        } else if (strcmp(type_str, "hold_mid") == 0) {
            type = 3;
        }

        data.push_back({pos, type, line_num});
    }
}

void processAndStoreData(const vector<Data>& data, vector<vector<int>>& rom) {
    for (const auto& d : data) {
        bitset<2> bits(d.type);
        rom[d.position][d.line * 2] = bits[0];
        rom[d.position][d.line * 2 + 1] = bits[1];
    }
}

void outputROM(const vector<vector<int>>& rom, const string& outputFilename) {
    ofstream outfile(outputFilename);
    outfile << "module ROM (\n";
    outfile << "    input [11:0] addr,\n";
    outfile << "    output reg [1:0] noteup,\n";
    outfile << "    output reg [1:0] notedown\n";
    outfile << ");\n\n";
    
    outfile << "reg [3:0] ROM [0:4095];\n\n";
    outfile << "initial begin\n";
    for (int i = 0; i < 4096; ++i) {
        outfile << "\tROM[" << i << "] = 4'b" << rom[i][3] << rom[i][2] << rom[i][1] << rom[i][0] << ";" << endl;
    }
    outfile << "end\n\n";
    outfile << "always @(*) begin\n";
    outfile << "    {noteup, notedown} = ROM[addr];\n";
    outfile << "end\n\n";
    outfile << "endmodule\n";
}

void modifyTop(const string& filename, const int bpm) {
    ifstream infile(filename);
    string line1, line2, restOfFile;
    ostringstream restOfFileStream;

    getline(infile, line1);
    getline(infile, line2);
    restOfFileStream << infile.rdbuf();
    restOfFile = restOfFileStream.str();

    ofstream outfile(filename);
    int div_cnt = 375000000 / bpm;
    outfile << line1 << endl;
    outfile << "\tparameter div_cnt = " << div_cnt << endl;
    outfile << restOfFile;
}

int main() {
    int bpm;
    vector<Data> data;
    readData("input_example.txt", bpm, data);

    vector<vector<int>> rom(4096, vector<int>(4, 0));
    processAndStoreData(data, rom);

    outputROM(rom, "../verilog/ROM.v");
    modifyTop("../verilog/MuseDash.v", bpm);

    return 0;
}