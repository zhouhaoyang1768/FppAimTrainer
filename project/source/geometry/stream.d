import std.conv;

class Stream {
public:
    string text; 
    int index;
    this(string text) {
        this.text = text;
        this.index = 0;
    }
    bool isWhiteSpace(char c) {
        import std.ascii;
        return isWhite(c);
    }
    void forward() {
        for(;index < text.length;){
            char c = text[index];
            if(isWhiteSpace(c)) ++index;
            else if (c == '#') {
                ++index;
                while (index < text.length && text[index] != '\n') {
                    ++index;
                }
                ++index;
            }
            else break;
        }
    }
    bool eof() {
        return index >= text.length;
    }
    string nextLine() {
        char[] ret = [];
        for(; index < text.length;) {
            if (text[index] != '\n') {
                ret ~= text[index];
                ++index;
            } else {
                ++index;
                break;
            }
        }
        return cast(string)ret;
    }
    string next() {
        char[] ret = [];
        forward();
        while(index < text.length && !isWhiteSpace(text[index])) {
            ret ~= text[index];
            ++index;
        }
        return cast(string)ret;
    }
    float nextFloat() {
        return to!float(next());
    }
    int nextInt() {
        return to!int(next());
    }
    ubyte nextUbyte() {
        return to!ubyte(next());
    }
}