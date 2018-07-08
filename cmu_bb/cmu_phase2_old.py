#!/usr/bin/python3

def finish_it():
    result = []

    for i in range(6):
        if i == 0:
            result.append(1)
        else:
            result.append(
                result[i-1] * (i+1)
                )
    return result


print(finish_it())
    


