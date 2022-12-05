require_relative '../verify'

let (:lines) { File.readlines("accelerated-domains.china.conf").filter { |line| !line.empty? } }

it "should find redundant domains" do
    expect(CheckRedundant(lines, [], 'qq.com')).to be == false
    expect(CheckRedundant(lines, [], 'www.qq.com')).to be == false
    expect(CheckRedundant(lines, [], 'qq.cn')).to be == false
    expect(CheckRedundant(lines, [], 'www.qq.cn')).to be == false
end

it "should add new domains" do
    expect(CheckRedundant(lines, [], 'what.a.wonderful.domain')).to be == "server=/what.a.wonderful.domain/114.114.114.114\n"
end
