#!/usr/bin/python3

def phase_2():
    result = []
    result.append(0)
    result.append(1)
    for i in range(0,4):
        result.append(result[i]+result[i+1])

    return result


print(phase_2())
    


