-- {"id":1284917360,"ver":"1.0.0","libVer":"1.0.0","author":"Philip R. Johnson (Hambone)"}

local baseURL = "https://deathworlders.com"

local function shrinkURL(url, t)
	return url:gsub("^.-deathworlders%.com/?", "")
end

local function expandURL(url, t)
	if url:sub(1, 1) ~= "/" then
		url = "/" .. url
	end
	return baseURL .. url
end

local function parseChapters(doc)
	local chapters = {}
	local links = doc:select("#list ul li a")
	for i = 0, links:size() - 1 do
		local a = links:get(i)
		local href = a:attr("href")
		if href:match("/chapter%-") then
			local title = a:text():gsub("^The Deathworlders%s*", "")
			chapters[#chapters + 1] = { link = href, title = title }
		end
	end
	return chapters
end

local function getLastPage(doc)
	local last = doc:selectFirst("a[aria-label=Last]")
	if last then
		local page = last:attr("href"):match("/page/(%d+)/")
		if page then return tonumber(page) end
	end
	return 1
end

return {
	id = 1,
	name = "Deathworlders",
	baseURL = baseURL,
	imageURL = "https://deathworlders.com/images/vemik.jpg",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Main", false, function()
			return {
				Novel {
					title = "The Deathworlders",
					link = "books/deathworlders/",
					imageURL = "https://deathworlders.com/images/vemik.jpg"
				}
			}
		end)
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(expandURL(url, KEY_NOVEL_URL))

		local desc = ""
		local ps = doc:select("#list > p")
		for i = 0, ps:size() - 1 do
			desc = desc .. ps:get(i):text() .. "\n\n"
		end

		local novel = NovelInfo {
			title = "The Deathworlders",
			imageURL = "https://deathworlders.com/images/vemik.jpg",
			description = desc,
			authors = { "Philip R. Johnson (Hambone)" },
			genres = { "Science Fiction", "HFY" },
			tags = { "Web Fiction", "Space Opera", "Alien Contact" },
			status = NovelStatus(3)
		}

		if loadChapters then
			local allChaps = parseChapters(doc)
			local maxPage = getLastPage(doc)

			for p = 2, maxPage do
				local pDoc = GETDocument(baseURL .. "/books/deathworlders/page/" .. p .. "/")
				local pageChaps = parseChapters(pDoc)
				for _, c in ipairs(pageChaps) do
					allChaps[#allChaps + 1] = c
				end
			end

			local chapters = {}
			for i = #allChaps, 1, -1 do
				chapters[#chapters + 1] = NovelChapter {
					order = #chapters + 1,
					title = allChaps[i].title,
					link = allChaps[i].link
				}
			end
			novel:setChapters(AsList(chapters))
		end

		return novel
	end,

	getPassage = function(url)
		local doc = GETDocument(expandURL(url, KEY_CHAPTER_URL))
		local article = doc:selectFirst("article")

		local aside = article:selectFirst("aside")
		if aside then aside:remove() end

		return pageOfElem(article, false)
	end,

	isSearchIncrementing = false,
	search = function(data) return {} end,
	searchFilters = {}
}
