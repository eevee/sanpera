from sanpera.geometry import Size, origin
from sanpera.image import Image, builtins


def test_cropped_canvas_fixing():
    img = builtins.rose.resized((200, 200))
    dim = Size(50, 50).at((25, 25))
    cropped = img.cropped(dim)

    assert cropped.size == dim.size
    assert cropped[0].canvas == dim.at(origin)


def test_cropped_canvas_fixing_large_crop():
    size = Size(20, 20)
    img = builtins.rose.resized(size)
    dim = Size(50, 50).at((-25, -25))
    cropped = img.cropped(dim)

    assert cropped.size == size
    assert cropped[0].canvas == size.at(origin)


def test_appending_to_an_empty_image():
    img = Image()
    img.append(builtins.rose[0])

    assert img.size == builtins.rose.size
