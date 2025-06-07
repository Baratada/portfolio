def isOpposite(a, b) -> bool:
    if len(a) == 0 and len(b) == 0:
        return True

    if len(a) != len(b) or a[0] == b[0]:
        return False

    if a[0] != b[-1]:
        return False

    return isOpposite(a[1:], b[:-1])

print(isOpposite([1,2,3], [3,2,1]))

