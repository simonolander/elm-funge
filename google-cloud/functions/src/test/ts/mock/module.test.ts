import dependency from "./dependency";
import module from "./module";

describe("mock", () => {
    it("should call the original dependency", () => {
        expect(module.fun()).toEqual(10);
    });

    it("should get the mocked return value", () => {
        const spy = jest.spyOn(dependency, "fun")
            .mockReturnValue(5);
        expect(module.fun()).toEqual(5);
        expect(spy.mock.calls.length).toEqual(1);
    });

    it("should call the mocked implementation", () => {
        const spy = jest.spyOn(dependency, "fun")
            .mockImplementation(() => 0);
        expect(module.fun()).toEqual(0);
        expect(spy.mock.calls.length).toEqual(1);

    });

    it("should call the original dependency again", () => {
        expect(module.fun()).toEqual(10);
    });
});
