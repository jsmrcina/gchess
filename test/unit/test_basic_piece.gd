extends GutTest

func test_basic_coord():
	var coord = Coord.new(1, 'A')
	assert_eq(coord.get_rank(), 1)
